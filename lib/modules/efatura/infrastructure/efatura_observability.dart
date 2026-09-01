import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

enum EfaturaApiErrorCategory {
  networkOffline,
  dnsError,
  tlsError,
  timeout,
  authFailed,
  sessionExpired,
  rateLimited,
  backendUnavailable,
  upstreamPortalUnavailable,
  malformedResponse,
  unknown,
}

extension EfaturaApiErrorCategoryCode on EfaturaApiErrorCategory {
  String get code => switch (this) {
    EfaturaApiErrorCategory.networkOffline => 'NETWORK_OFFLINE',
    EfaturaApiErrorCategory.dnsError => 'DNS_ERROR',
    EfaturaApiErrorCategory.tlsError => 'TLS_ERROR',
    EfaturaApiErrorCategory.timeout => 'TIMEOUT',
    EfaturaApiErrorCategory.authFailed => 'AUTH_FAILED',
    EfaturaApiErrorCategory.sessionExpired => 'SESSION_EXPIRED',
    EfaturaApiErrorCategory.rateLimited => 'RATE_LIMITED',
    EfaturaApiErrorCategory.backendUnavailable => 'BACKEND_UNAVAILABLE',
    EfaturaApiErrorCategory.upstreamPortalUnavailable =>
      'UPSTREAM_PORTAL_UNAVAILABLE',
    EfaturaApiErrorCategory.malformedResponse => 'MALFORMED_RESPONSE',
    EfaturaApiErrorCategory.unknown => 'UNKNOWN',
  };
}

final class EfaturaApiObservation {
  const EfaturaApiObservation({
    required this.correlationId,
    required this.route,
    required this.latencyMs,
    required this.manualAttempt,
    required this.attempt,
    this.httpStatus,
    this.errorCategory,
  });

  final String correlationId;
  final String route;
  final int? httpStatus;
  final int latencyMs;
  final EfaturaApiErrorCategory? errorCategory;
  final bool manualAttempt;
  final int attempt;

  Map<String, Object?> toSanitizedMap() => <String, Object?>{
    'correlationId': correlationId,
    'route': route,
    'httpStatus': httpStatus,
    'latencyMs': latencyMs,
    'errorCategory': errorCategory?.code,
    'manualAttempt': manualAttempt,
    'attempt': attempt,
  };
}

abstract interface class EfaturaObservabilitySink {
  void record(EfaturaApiObservation observation);
}

final class DeveloperEfaturaObservabilitySink
    implements EfaturaObservabilitySink {
  const DeveloperEfaturaObservabilitySink();

  @override
  void record(EfaturaApiObservation observation) {
    developer.log(
      jsonEncode(observation.toSanitizedMap()),
      name: 'taxy.efatura.api',
    );
  }
}

final class EfaturaCorrelationIdFactory {
  EfaturaCorrelationIdFactory({Random? random})
    : _random = random ?? Random.secure();
  final Random _random;

  String create() => List<int>.generate(
    16,
    (_) => _random.nextInt(256),
  ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}

String normalizeEfaturaRoute(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.length == 5 &&
      segments[0] == 'v1' &&
      segments[1] == 'efatura' &&
      segments[2] == 'sectors' &&
      segments[4] == 'invoices') {
    return '/v1/efatura/sectors/:sector/invoices';
  }
  const allowed = <String>{
    '/health',
    '/v1/efatura/sessions',
    '/v1/efatura/session',
    '/v1/efatura/overview',
    '/v1/efatura/invoices/pending',
  };
  return allowed.contains(uri.path) ? uri.path : '/unknown';
}
