import 'guest_phone.dart';
import 'guest_profile.dart';

/// A pending one-time-code verification for a phone number.
///
/// The backend OTP contract (code length, expiry, attempt budget) is not
/// approved yet, so the values here come from the `09 · Authentication`
/// reference: a 6-box code and a limited number of attempts before the guest
/// must request a new code. [attemptsRemaining] travels with the challenge so
/// verification stays a pure function of its inputs — no hidden counters.
class OtpChallenge {
  const OtpChallenge({
    required this.challengeId,
    required this.phone,
    this.codeLength = 6,
    this.attemptsRemaining = 3,
  });

  final String challengeId;
  final GuestPhone phone;
  final int codeLength;
  final int attemptsRemaining;

  bool get isLockedOut => attemptsRemaining <= 0;

  OtpChallenge copyWith({int? attemptsRemaining}) => OtpChallenge(
        challengeId: challengeId,
        phone: phone,
        codeLength: codeLength,
        attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
      );

  @override
  bool operator ==(Object other) =>
      other is OtpChallenge &&
      other.challengeId == challengeId &&
      other.phone == phone &&
      other.codeLength == codeLength &&
      other.attemptsRemaining == attemptsRemaining;

  @override
  int get hashCode =>
      Object.hash(challengeId, phone, codeLength, attemptsRemaining);
}

/// Result of submitting a code for an [OtpChallenge].
///
/// Modelled as explicit states rather than a bool + error flags
/// (feature_guide.md Step 6): the presentation layer switches on this to decide
/// whether to advance, show the "incorrect code" banner, or show the lock-out
/// banner. Infrastructure problems (offline, server) are still thrown as a
/// `Failure` and never appear here.
sealed class OtpVerification {
  const OtpVerification();

  const factory OtpVerification.authenticated(AuthSession session) =
      OtpAuthenticated;
  const factory OtpVerification.rejected(OtpChallenge challenge) = OtpRejected;
  const factory OtpVerification.lockedOut(OtpChallenge challenge) = OtpLockedOut;
}

class OtpAuthenticated extends OtpVerification {
  const OtpAuthenticated(this.session);
  final AuthSession session;
}

class OtpRejected extends OtpVerification {
  const OtpRejected(this.challenge);

  /// The challenge with [OtpChallenge.attemptsRemaining] already decremented.
  final OtpChallenge challenge;
}

class OtpLockedOut extends OtpVerification {
  const OtpLockedOut(this.challenge);
  final OtpChallenge challenge;
}
