abstract final class EfaturaApiConfiguration {
  static const productionBaseUrl = 'https://api.taxy.pt/';
  static const contractVersion = 1;

  static const _configuredBaseUrl = String.fromEnvironment(
    'TAXY_API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  /// The app deliberately accepts only the public Taxy API in normal builds.
  /// A bad build-time value fails closed instead of selecting an older backend
  /// or the direct FactIntWS research connector.
  static Uri get baseUri {
    final uri = Uri.parse(_configuredBaseUrl);
    if (uri.scheme != 'https' ||
        uri.host != 'api.taxy.pt' ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443) ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw StateError('Invalid TAXY_API_BASE_URL');
    }
    return uri.replace(path: '/');
  }
}
