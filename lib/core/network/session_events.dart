import 'dart:async';

/// Broadcasts "the backend rejected the stored access token" — an HTTP 401 on
/// a request that carried one — so the authentication feature can end the
/// session (`AuthController.expireSession`) without core depending on it.
class SessionEvents {
  final StreamController<void> _tokenRejected =
      StreamController<void>.broadcast();

  Stream<void> get tokenRejected => _tokenRejected.stream;

  void reportTokenRejected() {
    if (!_tokenRejected.isClosed) _tokenRejected.add(null);
  }

  void dispose() => _tokenRejected.close();
}
