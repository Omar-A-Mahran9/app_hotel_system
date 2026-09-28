/// Data-layer models for the authentication endpoints.
///
/// They mirror the shape the Laravel API is expected to return inside the
/// standard `{success, message, data}` envelope. The exact contract is not
/// approved yet, so the API data source that would parse these is a documented
/// stub (see `api_auth_data_source.dart`); the models exist so the dummy and
/// API sources share one return type.
class OtpChallengeModel {
  const OtpChallengeModel({
    required this.challengeId,
    required this.phoneE164,
    required this.codeLength,
    required this.attemptsRemaining,
  });

  final String challengeId;
  final String phoneE164;
  final int codeLength;
  final int attemptsRemaining;

  factory OtpChallengeModel.fromJson(Map<String, dynamic> json) {
    return OtpChallengeModel(
      challengeId: json['challenge_id'] as String,
      phoneE164: json['phone'] as String,
      codeLength: (json['code_length'] as num?)?.toInt() ?? 6,
      attemptsRemaining: (json['attempts_remaining'] as num?)?.toInt() ?? 3,
    );
  }
}

/// Outcome of a verify/complete-profile call from the data-source layer.
class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.phoneE164,
    this.fullName,
    this.email,
  });

  final String accessToken;
  final String phoneE164;
  final String? fullName;
  final String? email;

  /// Parses the `data` object of a successful `POST /guest/auth/otp/verify`
  /// (`{outcome:"authenticated", token, guest:{...}}`).
  factory AuthSessionModel.fromVerify(Map<String, dynamic> data) {
    final Map<String, dynamic> guest =
        (data['guest'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return AuthSessionModel(
      accessToken: data['token'] as String,
      phoneE164: guest['phone'] as String? ?? '',
      fullName: guest['name'] as String?,
      email: guest['email'] as String?,
    );
  }

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> guest =
        (json['guest'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return AuthSessionModel(
      accessToken: json['token'] as String? ?? json['access_token'] as String,
      phoneE164: guest['phone'] as String? ?? json['phone'] as String? ?? '',
      fullName: guest['name'] as String?,
      email: guest['email'] as String?,
    );
  }
}

/// Data-source verify result. Wrong-code and lock-out are ordinary outcomes of
/// the auth flow, so they are modelled here rather than thrown.
sealed class OtpVerifyResult {
  const OtpVerifyResult();
}

class OtpVerifyAccepted extends OtpVerifyResult {
  const OtpVerifyAccepted(this.session);
  final AuthSessionModel session;
}

class OtpVerifyRejected extends OtpVerifyResult {
  const OtpVerifyRejected({required this.attemptsRemaining});
  final int attemptsRemaining;
}

class OtpVerifyLockedOut extends OtpVerifyResult {
  const OtpVerifyLockedOut();
}
