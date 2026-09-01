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
