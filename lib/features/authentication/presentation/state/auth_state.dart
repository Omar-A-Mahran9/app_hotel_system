import '../../domain/entities/guest_profile.dart';

/// Top-level authentication state. This is the single fact the router redirects
/// on (feature_guide.md Step 6) — deliberately explicit rather than a set of
/// `isLoading` / `isAuthenticated` booleans.
sealed class AuthState {
  const AuthState();

  const factory AuthState.unknown() = AuthUnknown;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.awaitingProfile(AuthSession session) =
      AuthAwaitingProfile;
  const factory AuthState.authenticated(AuthSession session) = Authenticated;
  const factory AuthState.sessionExpired() = AuthSessionExpired;

  T map<T>({
    required T Function() unknown,
    required T Function() unauthenticated,
    required T Function(AuthSession session) awaitingProfile,
    required T Function(AuthSession session) authenticated,
    required T Function() sessionExpired,
  }) {
    return switch (this) {
      AuthUnknown() => unknown(),
      AuthUnauthenticated() => unauthenticated(),
      AuthAwaitingProfile(:final AuthSession session) => awaitingProfile(
        session,
      ),
      Authenticated(:final AuthSession session) => authenticated(session),
      AuthSessionExpired() => sessionExpired(),
    };
  }
}

/// Startup: a stored session is being restored.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// No session — the entry + sign-in surface is shown.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Code verified but the first-time guest still owes a name + email
/// (`إكمال البيانات`).
class AuthAwaitingProfile extends AuthState {
  const AuthAwaitingProfile(this.session);
  final AuthSession session;

  @override
  bool operator ==(Object other) =>
      other is AuthAwaitingProfile && other.session == session;

  @override
  int get hashCode => session.hashCode;
}

/// Fully signed in.
class Authenticated extends AuthState {
  const Authenticated(this.session);
  final AuthSession session;

  @override
  bool operator ==(Object other) =>
      other is Authenticated && other.session == session;

  @override
  int get hashCode => session.hashCode;
}

/// A previously valid session was rejected by the backend (`انتهت الجلسة`).
/// Reached when the API layer reports `401` in a later phase; surfaced now so
/// the screen, state and routing exist and are tested.
class AuthSessionExpired extends AuthState {
  const AuthSessionExpired();
}
