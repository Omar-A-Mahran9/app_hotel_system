/// Rewrites a backend-returned absolute media URL (`cover_url`,
/// `gallery[].url`, …) onto the same host the client already uses to reach
/// the API — it never fabricates a URL, only re-hosts a real one.
///
/// The Laravel API bakes its own `APP_URL` into these absolute URLs
/// (typically `http://localhost:8000` in local dev) with no notion of which
/// network the mobile client is running on. That host is reachable from a
/// browser tab or a machine sitting next to the server, but not from an
/// Android emulator — where `localhost` resolves to the emulator itself, not
/// the developer machine — even though the *API call* that returned the JSON
/// succeeded (API calls go through [AppConfig.apiBaseUrl] / `10.0.2.2`, not
/// the literal host embedded in the response body).
///
/// Only a small set of well-known local-dev hosts are ever rewritten, and
/// only when they differ from the configured API host; anything else (a real
/// CDN, staging, or production domain) is assumed to already be reachable
/// and is returned unchanged.
class ApiImageUrlResolver {
  const ApiImageUrlResolver(this._apiBaseUrl);

  final String _apiBaseUrl;

  /// Hosts a local Laravel dev server commonly binds to / is reached
  /// through. A URL whose host is *not* in this set is treated as an
  /// already-real, externally reachable address.
  static const Set<String> _devLoopbackHosts = <String>{
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '10.0.2.2',
  };

  /// Returns [rawUrl] re-hosted onto the configured API origin when it
  /// points at a dev loopback host the current client cannot reach;
  /// otherwise returns it unchanged. `null`/empty input passes through as-is
  /// — this never invents a URL where the API didn't return one.
  String? resolve(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return rawUrl;

    final Uri? raw = Uri.tryParse(rawUrl);
    if (raw == null || !raw.hasScheme || raw.host.isEmpty) return rawUrl;
    if (!_devLoopbackHosts.contains(raw.host)) return rawUrl;

    final Uri? base = Uri.tryParse(_apiBaseUrl);
    if (base == null || !base.hasScheme || base.host.isEmpty) return rawUrl;
    if (raw.scheme == base.scheme && raw.host == base.host && raw.port == base.port) {
      return rawUrl;
    }

    return raw.replace(scheme: base.scheme, host: base.host, port: base.port).toString();
  }
}
