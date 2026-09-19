import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/official_prefill_evidence.dart';

const bool officialAtPrefillEnabled = bool.fromEnvironment(
  'TAXY_AT_PREFILL_ENABLED',
  defaultValue: true,
);

enum OfficialPrefillFailureKind {
  authentication,
  unavailable,
  network,
  parsing,
  unsupportedYear,
  unknown,
}

final class OfficialPrefillException implements Exception {
  const OfficialPrefillException(this.kind, this.safeMessage);
  final OfficialPrefillFailureKind kind;
  final String safeMessage;
}

final class OfficialPrefillCredentials {
  const OfficialPrefillCredentials({required this.nif, required this.password});
  final String nif;
  final String password;
}

abstract interface class OfficialPrefillGateway {
  Future<OfficialPrefillEvidence> load({
    required OfficialPrefillCredentials credentials,
    required int taxYear,
  });
}

abstract interface class OfficialPrefillTransport {
  Future<OfficialPrefillResponse> post(Uri uri, Map<String, Object?> body);
}

final class OfficialPrefillResponse {
  const OfficialPrefillResponse(this.statusCode, this.body);
  final int statusCode;
  final Map<String, Object?> body;
}

/// One-shot, read-only Portal prefill bridge.
///
/// Credentials exist only for the duration of this call. Flutter receives a
/// normalized response with no taxpayer identifiers, cookies or raw AT model.
final class BackendOfficialPrefillGateway implements OfficialPrefillGateway {
  BackendOfficialPrefillGateway({
    required Uri baseUri,
    OfficialPrefillTransport? transport,
  }) : _baseUri = _validatedBaseUri(baseUri),
       _transport = transport ?? IoOfficialPrefillTransport();

  final Uri _baseUri;
  final OfficialPrefillTransport _transport;

  @override
  Future<OfficialPrefillEvidence> load({
    required OfficialPrefillCredentials credentials,
    required int taxYear,
  }) async {
    if (!RegExp(r'^\d{9}$').hasMatch(credentials.nif) ||
        credentials.password.isEmpty) {
      throw const OfficialPrefillException(
        OfficialPrefillFailureKind.authentication,
        'Indica um NIF de nove dígitos e a senha do Portal das Finanças.',
      );
    }
    if (taxYear != 2024 && taxYear != 2025) {
      throw const OfficialPrefillException(
        OfficialPrefillFailureKind.unsupportedYear,
        'Este ano fiscal ainda não está disponível para importação.',
      );
    }
    try {
      final response = await _transport.post(
        _baseUri.resolve('v1/irs/prefill'),
        <String, Object?>{
          'nif': credentials.nif,
          'password': credentials.password,
          'taxYear': taxYear,
        },
      );
      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        throw const OfficialPrefillException(
          OfficialPrefillFailureKind.authentication,
          'Não foi possível autenticar no Portal das Finanças.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const OfficialPrefillException(
          OfficialPrefillFailureKind.unavailable,
          'A importação oficial não está disponível de momento.',
        );
      }
      final prefill = response.body['prefill'];
      if (prefill is! Map) throw const FormatException('prefill');
      final evidence = OfficialPrefillEvidence.fromJson(
        prefill.cast<String, Object?>(),
      );
      if (evidence.taxYear != taxYear) {
        throw const FormatException('wrong tax year');
      }
      return evidence;
    } on OfficialPrefillException {
      rethrow;
    } on TimeoutException {
      throw const OfficialPrefillException(
        OfficialPrefillFailureKind.network,
        'Não foi possível estabelecer ligação.',
      );
    } on SocketException {
      throw const OfficialPrefillException(
        OfficialPrefillFailureKind.network,
        'Não foi possível estabelecer ligação.',
      );
    } on HandshakeException {
      throw const OfficialPrefillException(
        OfficialPrefillFailureKind.network,
        'Não foi possível estabelecer uma ligação segura.',
      );
    } on FormatException {
      throw const OfficialPrefillException(
        OfficialPrefillFailureKind.parsing,
        'A AT devolveu dados que a Taxy ainda não consegue interpretar com segurança.',
      );
    }
  }
}

final class IoOfficialPrefillTransport implements OfficialPrefillTransport {
  IoOfficialPrefillTransport({
    HttpClient? client,
    this.timeout = const Duration(seconds: 90),
    this.maximumResponseBytes = 2 * 1024 * 1024,
  }) : _client = client ?? HttpClient();

  final HttpClient _client;
  final Duration timeout;
  final int maximumResponseBytes;

  @override
  Future<OfficialPrefillResponse> post(
    Uri uri,
    Map<String, Object?> body,
  ) async {
    final request = await _client.postUrl(uri).timeout(timeout);
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(timeout);
    final bytes = <int>[];
    await for (final chunk in response.timeout(timeout)) {
      if (bytes.length + chunk.length > maximumResponseBytes) {
        throw const FormatException('response too large');
      }
      bytes.addAll(chunk);
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException('response');
    return OfficialPrefillResponse(
      response.statusCode,
      decoded.cast<String, Object?>(),
    );
  }
}

Uri _validatedBaseUri(Uri uri) {
  if (uri.scheme != 'https' ||
      uri.host != 'api.taxy.pt' ||
      uri.userInfo.isNotEmpty) {
    throw ArgumentError.value(uri, 'baseUri', 'Taxy HTTPS backend required');
  }
  return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}
