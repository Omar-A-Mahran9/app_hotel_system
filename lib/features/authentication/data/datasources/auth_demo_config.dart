/// Development-only constants for [DummyAuthDataSource].
///
/// The approved SRS/UI does not define demo credentials or an OTP policy, so —
/// per the phase brief — this is a deterministic stand-in, NOT a production
/// credential policy. Nothing here is a secret: it is a fixed test code and a
/// list of fixture phone numbers. The real values come from the backend
/// authentication contract when it is approved, at which point
/// `ApiAuthDataSource` replaces this entirely.
abstract final class AuthDemoConfig {
  /// The only code the dummy source accepts. Shown to the user on the OTP
  /// screen in development builds so the flow is walkable without a real SMS.
  static const String acceptedCode = '123456';

  /// 6 boxes in `09 · Authentication`.
  static const int codeLength = 6;

  /// The guest gets this many tries before the challenge locks and a new code
  /// is required (the reference shows attempts counting down).
  static const int maxAttempts = 3;

  /// Countdown before "Resend the code" becomes available (`00:42` in the
  /// reference). This is a presentation timer only.
  static const Duration resendCooldown = Duration(seconds: 42);

  /// E.164 numbers treated as returning guests: verification signs them
  /// straight in without the "complete your details" step. Every other number
  /// is treated as a first-time guest.
  static const Set<String> returningGuests = <String>{
    '+966500000000',
  };
}
