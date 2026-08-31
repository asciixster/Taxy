import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../application/efatura_read_only_service.dart';
import '../domain/efatura_models.dart';
import 'efatura_runtime_bridge.dart';
import 'efatura_wire_mapping.dart';

abstract interface class EfaturaBackendTransport {
  Future<EfaturaBackendResponse> send({
    required String method,
    required Uri uri,
    String? bearerToken,
    Map<String, Object?>? body,
  });
}

final class EfaturaBackendResponse {
  const EfaturaBackendResponse({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, Object?> body;
}

/// Read-only Taxy backend bridge.
///
/// Portal credentials are sent once over HTTPS to create a short-lived backend
/// session. Flutter retains only the opaque session token in memory. The token
/// is discarded on disconnect and is never exposed through application state.
final class BackendEfaturaRuntimeBridge
    implements
        EfaturaReadOnlyGateway,
        EfaturaCredentialStore,
        EfaturaRuntimeProvisioning {
  BackendEfaturaRuntimeBridge({
    required Uri baseUri,
    EfaturaBackendTransport? transport,
    this.screenProtection,
  }) : _baseUri = _validatedBaseUri(baseUri),
       _transport = transport ?? IoEfaturaBackendTransport();

  final Uri _baseUri;
  final EfaturaBackendTransport _transport;
  final EfaturaRuntimeProvisioning? screenProtection;
  String? _sessionToken;
  EfaturaOverview? _connectOverview;

  @override
  Future<void> save(EfaturaCredentials credentials) async {
    if (!RegExp(r'^\d{9}$').hasMatch(credentials.nif) ||
        credentials.password.isEmpty) {
      throw const EfaturaServiceException(
        EfaturaFailureKind.authentication,
        'Indica um NIF de nove dígitos e a senha do Portal das Finanças.',
      );
    }
    final response = await _send(
      method: 'POST',
      path: 'v1/efatura/sessions',
      body: <String, Object?>{
        'nif': credentials.nif,
        'password': credentials.password,
      },
      authenticated: false,
    );
    final token = response['sessionToken'];
    final overview = response['overview'];
    if (token is! String ||
        token.trim().isEmpty ||
        overview is! Map<String, Object?>) {
      throw const EfaturaServiceException(
        EfaturaFailureKind.parsing,
        'Recebemos uma resposta inesperada do e-Fatura.',
      );
    }
    final parsedOverview = efaturaOverviewFromMap(overview);
    _sessionToken = token;
    _connectOverview = parsedOverview;
  }

  @override
  Future<EfaturaRuntimeReadiness> load() async => EfaturaRuntimeReadiness(
    hasCredentials: _sessionToken != null,
    hasClientIdentity: true,
    hasCipherCertificate: true,
  );

  @override
  Future<bool> hasCredentials() async => _sessionToken != null;

  @override
  Future<void> clear() async {
    final token = _sessionToken;
    _sessionToken = null;
    _connectOverview = null;
    if (token == null) return;
    try {
      await _transport.send(
        method: 'DELETE',
        uri: _resolve('v1/efatura/session'),
        bearerToken: token,
      );
    } catch (_) {
      // The local capability is already gone. Remote sessions have a short
      // mandatory TTL, so logout remains fail-closed without retaining token.
    }
  }

  @override
  Future<EfaturaOverview> fetchOverview() async {
    final cached = _connectOverview;
    if (cached != null) {
      _connectOverview = null;
      return cached;
    }
    final value = await _send(method: 'GET', path: 'v1/efatura/overview');
    final overview = value['overview'];
    if (overview is! Map<String, Object?>) {
      throw const EfaturaServiceException(
        EfaturaFailureKind.parsing,
        'Recebemos uma resposta inesperada do e-Fatura.',
      );
    }
    return efaturaOverviewFromMap(overview);
  }

  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async {
    final value = await _send(
      method: 'GET',
      path: 'v1/efatura/invoices/pending',
    );
    return efaturaInvoiceList(value['invoices']);
  }

  @override
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode) async {
    if (!RegExp(r'^C(?:0[1-9]|1[0-5]|99)$').hasMatch(sectorCode)) {
      throw const EfaturaServiceException(
        EfaturaFailureKind.business,
        'O setor devolvido pelo serviço ainda não é reconhecido.',
      );
    }
    final value = await _send(
      method: 'GET',
      path: 'v1/efatura/sectors/${Uri.encodeComponent(sectorCode)}/invoices',
    );
    return efaturaInvoiceList(value['invoices']);
  }

  Future<Map<String, Object?>> _send({
    required String method,
    required String path,
    Map<String, Object?>? body,
    bool authenticated = true,
  }) async {
    final token = authenticated ? _sessionToken : null;
    if (authenticated && token == null) {
      throw const EfaturaServiceException(
        EfaturaFailureKind.notConfigured,
        'Liga primeiro o e-Fatura com as tuas credenciais.',
      );
    }
    try {
      final response = await _transport.send(
        method: method,
        uri: _resolve(path),
        bearerToken: token,
        body: body,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      throw _backendFailure(response.statusCode, response.body);
    } on EfaturaServiceException {
      rethrow;
    } on TimeoutException {
      throw const EfaturaServiceException(
        EfaturaFailureKind.network,
        'Não foi possível estabelecer ligação.',
      );
    } on SocketException {
      throw const EfaturaServiceException(
        EfaturaFailureKind.network,
        'Não foi possível estabelecer ligação.',
      );
    } on HandshakeException {
      throw const EfaturaServiceException(
        EfaturaFailureKind.tls,
        'Não foi possível estabelecer uma ligação segura.',
      );
    } on FormatException {
      throw const EfaturaServiceException(
        EfaturaFailureKind.parsing,
        'Recebemos uma resposta inesperada do e-Fatura.',
      );
    }
  }

  @override
  Future<bool> selectClientIdentity() async => true;

  @override
  Future<bool> selectCipherCertificate() async => true;

  @override
  Future<void> setScreenSecure(bool enabled) async =>
      screenProtection?.setScreenSecure(enabled);

  Uri _resolve(String path) => _baseUri.resolve(path);
}

final class IoEfaturaBackendTransport implements EfaturaBackendTransport {
  IoEfaturaBackendTransport({
    HttpClient? client,
    this.timeout = const Duration(seconds: 30),
    this.maximumResponseBytes = 1024 * 1024,
  }) : _client = client ?? HttpClient();

  final HttpClient _client;
  final Duration timeout;
  final int maximumResponseBytes;

  @override
  Future<EfaturaBackendResponse> send({
    required String method,
    required Uri uri,
    String? bearerToken,
    Map<String, Object?>? body,
  }) async {
    if (uri.scheme != 'https') {
      throw const EfaturaServiceException(
        EfaturaFailureKind.notConfigured,
        'A ligação segura ao backend e-Fatura não está configurada.',
      );
    }
    final request = await _client.openUrl(method, uri).timeout(timeout);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    if (bearerToken != null) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $bearerToken',
      );
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));
    }
    final response = await request.close().timeout(timeout);
    final bytes = <int>[];
    await for (final chunk in response.timeout(timeout)) {
      if (bytes.length + chunk.length > maximumResponseBytes) {
        throw const EfaturaServiceException(
          EfaturaFailureKind.parsing,
          'Recebemos uma resposta inesperada do e-Fatura.',
        );
      }
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty && response.statusCode == HttpStatus.noContent) {
      return EfaturaBackendResponse(
        statusCode: response.statusCode,
        body: const {},
      );
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) throw const FormatException();
    return EfaturaBackendResponse(
      statusCode: response.statusCode,
      body: decoded,
    );
  }
}

EfaturaServiceException _backendFailure(
  int statusCode,
  Map<String, Object?> body,
) {
  final code = body['code']?.toString();
  final kind = switch (code) {
    'AUTH_ERROR' => EfaturaFailureKind.authentication,
    'AUTHORIZATION_ERROR' => EfaturaFailureKind.authorization,
    'SESSION_EXPIRED' => EfaturaFailureKind.expired,
    'NETWORK_ERROR' => EfaturaFailureKind.network,
    'SERVICE_ERROR' => EfaturaFailureKind.serviceUnavailable,
    'BUSINESS_ERROR' => EfaturaFailureKind.business,
    'PARSING_ERROR' => EfaturaFailureKind.parsing,
    _ when statusCode == HttpStatus.unauthorized =>
      EfaturaFailureKind.authentication,
    _ when statusCode == HttpStatus.forbidden =>
      EfaturaFailureKind.authorization,
    _ when statusCode >= 500 => EfaturaFailureKind.serviceUnavailable,
    _ => EfaturaFailureKind.unknown,
  };
  return EfaturaServiceException(kind, switch (kind) {
    EfaturaFailureKind.authentication =>
      'Não foi possível autenticar no Portal das Finanças.',
    EfaturaFailureKind.authorization =>
      'Não foi possível autorizar a consulta e-Fatura.',
    EfaturaFailureKind.expired =>
      'A ligação ao e-Fatura expirou. Liga novamente para continuar.',
    EfaturaFailureKind.network => 'Não foi possível estabelecer ligação.',
    EfaturaFailureKind.serviceUnavailable =>
      'O serviço e-Fatura não está disponível de momento.',
    EfaturaFailureKind.business =>
      'O e-Fatura não conseguiu concluir a consulta.',
    EfaturaFailureKind.parsing =>
      'Recebemos uma resposta inesperada do e-Fatura.',
    _ => 'Não foi possível consultar o e-Fatura.',
  });
}

Uri _validatedBaseUri(Uri uri) {
  if (uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    throw ArgumentError.value(uri, 'baseUri', 'HTTPS backend URL required');
  }
  return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}
