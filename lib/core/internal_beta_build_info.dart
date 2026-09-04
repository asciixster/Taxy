abstract final class InternalBetaBuildInfo {
  static const appVersion = String.fromEnvironment(
    'TAXY_APP_VERSION',
    defaultValue: '0.8.0',
  );
  static const buildNumber = String.fromEnvironment(
    'TAXY_BUILD_NUMBER',
    defaultValue: '16',
  );
  static const gitShortSha = String.fromEnvironment(
    'TAXY_GIT_SHA',
    defaultValue: 'development',
  );
  static const environment = String.fromEnvironment(
    'TAXY_BUILD_ENVIRONMENT',
    defaultValue: 'production',
  );
  static const apiHost = 'api.taxy.pt';

  static bool get isInternalBeta => environment == 'internal-beta';
}
