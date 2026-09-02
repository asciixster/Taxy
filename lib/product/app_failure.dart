enum AppFailureKind {
  networkOffline,
  timeout,
  authenticationRequired,
  authorizationDenied,
  sessionExpired,
  serviceUnavailable,
  serverError,
  malformedData,
  missingRequiredData,
  localDataError,
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
    AppFailureKind.authorizationDenied => 'AUTHORIZATION_DENIED',
    AppFailureKind.sessionExpired => 'SESSION_EXPIRED',
    AppFailureKind.serviceUnavailable => 'SERVICE_UNAVAILABLE',
    AppFailureKind.serverError => 'SERVER_ERROR',
    AppFailureKind.malformedData => 'MALFORMED_DATA',
    AppFailureKind.missingRequiredData => 'MISSING_REQUIRED_DATA',
    AppFailureKind.localDataError => 'LOCAL_DATA_ERROR',
    AppFailureKind.unknown => 'UNKNOWN',
  };
}
