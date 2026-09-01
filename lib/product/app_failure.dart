enum AppFailureKind {
  networkOffline,
  timeout,
  authenticationRequired,
  sessionExpired,
  serviceUnavailable,
  malformedData,
  missingRequiredData,
  unknown,
}

/// Shared presentation state. `stale` is valid only when a module has a
/// documented persisted snapshot; e-Fatura deliberately does not use it.
enum AppDataState { online, offline, loading, stale, unavailable, error }

final class AppFailure implements Exception {
  const AppFailure(this.kind, {this.correlationId});

  final AppFailureKind kind;
  final String? correlationId;

  String get diagnosticCode => switch (kind) {
    AppFailureKind.networkOffline => 'NETWORK_OFFLINE',
    AppFailureKind.timeout => 'TIMEOUT',
    AppFailureKind.authenticationRequired => 'AUTH_REQUIRED',
    AppFailureKind.sessionExpired => 'SESSION_EXPIRED',
    AppFailureKind.serviceUnavailable => 'SERVICE_UNAVAILABLE',
    AppFailureKind.malformedData => 'MALFORMED_DATA',
    AppFailureKind.missingRequiredData => 'MISSING_REQUIRED_DATA',
    AppFailureKind.unknown => 'UNKNOWN',
  };
}
