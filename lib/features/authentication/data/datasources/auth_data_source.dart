import '../models/auth_models.dart';

/// Data-source contract for guest authentication. Concrete implementations are
/// [DummyAuthDataSource] (Phase 1) and [ApiAuthDataSource] (later, once the
/// backend contract is approved). Both honour the same behaviour, including
/// error behaviour (coding_rules.md §7).
abstract interface class AuthDataSource {
  /// Rebuilds the session for a persisted [accessToken] by calling the
  /// backend `me` endpoint. Returns `null` when the token is no longer
  /// valid (the caller then clears local state). Infrastructure errors are
  /// thrown as usual.
  Future<AuthSessionModel?> fetchCurrentSession(String accessToken);

  Future<OtpChallengeModel> requestOtp(String phoneE164);

  Future<OtpChallengeModel> resendOtp({
    required String challengeId,
    required String phoneE164,
  });

  Future<OtpVerifyResult> verifyOtp({
    required String challengeId,
    required String phoneE164,
    required int attemptsRemaining,
    required String code,
  });

  Future<AuthSessionModel> completeProfile({
    required String accessToken,
    required String phoneE164,
    required String fullName,
    required String email,
  });

  /// Revokes the current access token on the backend
  /// (`POST /guest/auth/logout`), so it can no longer authorise any guest
  /// call. A token the backend already rejects counts as revoked.
  Future<void> revokeSession();
}
