import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/auth_models.dart';
import 'auth_data_source.dart';
import 'auth_demo_config.dart';

/// Deterministic, offline authentication source used while no approved backend
/// auth endpoint is wired.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness;
/// * results depend only on the method arguments (attempt counting is driven by
///   the `attemptsRemaining` the caller passes in, not a hidden field);
/// * the accepted code and returning-guest list come from [AuthDemoConfig] and
///   are development-only.
class DummyAuthDataSource implements AuthDataSource, DummyDataSource {
  const DummyAuthDataSource();

  OtpChallengeModel _challengeFor(String phoneE164) => OtpChallengeModel(
        challengeId: 'dummy-challenge:$phoneE164',
        phoneE164: phoneE164,
        codeLength: AuthDemoConfig.codeLength,
        attemptsRemaining: AuthDemoConfig.maxAttempts,
      );

  @override
  Future<AuthSessionModel?> fetchCurrentSession(String accessToken) async {
    // The dummy token encodes the phone: `dummy-token:+9665...`.
    final int sep = accessToken.indexOf(':');
    if (!accessToken.startsWith('dummy-token:') || sep < 0) return null;
    final String phone = accessToken.substring(sep + 1);
    final bool returning = AuthDemoConfig.returningGuests.contains(phone);
    return AuthSessionModel(
      accessToken: accessToken,
      phoneE164: phone,
      fullName: returning ? 'Returning Guest' : null,
      email: returning ? 'returning.guest@example.com' : null,
    );
  }

  @override
  Future<OtpChallengeModel> requestOtp(String phoneE164) async {
    _assertPlausible(phoneE164);
    return _challengeFor(phoneE164);
  }

  @override
  Future<OtpChallengeModel> resendOtp({
    required String challengeId,
    required String phoneE164,
  }) async {
    _assertPlausible(phoneE164);
    return _challengeFor(phoneE164);
  }

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String challengeId,
    required String phoneE164,
    required int attemptsRemaining,
    required String code,
  }) async {
    if (attemptsRemaining <= 0) return const OtpVerifyLockedOut();

    if (code == AuthDemoConfig.acceptedCode) {
      final bool returning =
          AuthDemoConfig.returningGuests.contains(phoneE164);
      return OtpVerifyAccepted(
        AuthSessionModel(
          accessToken: 'dummy-token:$phoneE164',
          phoneE164: phoneE164,
          fullName: returning ? 'Returning Guest' : null,
          email: returning ? 'returning.guest@example.com' : null,
        ),
      );
    }

    final int left = attemptsRemaining - 1;
    return left <= 0
        ? const OtpVerifyLockedOut()
        : OtpVerifyRejected(attemptsRemaining: left);
  }

  @override
  Future<AuthSessionModel> completeProfile({
    required String accessToken,
    required String phoneE164,
    required String fullName,
    required String email,
  }) async {
    if (fullName.trim().isEmpty || email.trim().isEmpty) {
      throw const ValidationException(<String, List<String>>{});
    }
    return AuthSessionModel(
      accessToken: accessToken,
      phoneE164: phoneE164,
      fullName: fullName.trim(),
      email: email.trim(),
    );
  }

  @override
  Future<void> revokeSession() async {
    // No server-side session exists in demo mode.
  }

  void _assertPlausible(String phoneE164) {
    if (!RegExp(r'^\+\d{7,15}$').hasMatch(phoneE164)) {
      throw const ValidationException(<String, List<String>>{});
    }
  }
}
