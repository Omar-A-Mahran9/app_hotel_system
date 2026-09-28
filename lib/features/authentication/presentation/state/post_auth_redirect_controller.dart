import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where to send the guest once they finish signing in.
///
/// Authentication is deferred until the guest commits to a booking
/// (`docs/mobile-deferred-auth.md`). The screen that hits the auth gate — today
/// only [RoomSelectionReviewPage] — [remember]s its own location before routing
/// to sign-in; the router [consume]s it when [AuthState] becomes
/// `authenticated`, so the guest lands back where they were with the room
/// selection intact.
///
/// In-memory only, like `languageSelectedProvider` — a redirect target never
/// needs to outlive the process.
class PostAuthRedirect extends Notifier<String?> {
  @override
  String? build() => null;

  /// Records [location] (a full `GoRouter` URI string) as the post-sign-in
  /// destination. Called from the widget that triggers sign-in, never from a
  /// provider `build`.
  void remember(String location) => state = location;

  /// Returns the remembered destination and clears it, so it is used exactly
  /// once.
  String? consume() {
    final String? target = state;
    state = null;
    return target;
  }
}

final postAuthRedirectProvider = NotifierProvider<PostAuthRedirect, String?>(
  PostAuthRedirect.new,
);
