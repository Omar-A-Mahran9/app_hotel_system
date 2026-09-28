import 'package:dio/dio.dart';

import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';
import 'auth_data_source.dart';

/// API-backed guest authentication against the Laravel `/api/v1/guest/auth/*`
/// surface (Slice 0). Contract — `md/integration-contract-matrix.md`:
///
/// * `POST /guest/auth/otp/request`  `{phone}`                        → challenge
/// * `POST /guest/auth/otp/resend`   `{challenge_id, phone}`          → challenge
/// * `POST /guest/auth/otp/verify`   `{challenge_id, phone, code}`    → outcome
/// * `PATCH /guest/profile`          `{name, email}`  (bearer token)  → guest
/// * `POST /guest/auth/logout`                        (bearer token)  → revoke
///
/// Wrong code / lock-out come back as **200** with an `outcome` discriminator,
/// not as errors — mirrored here onto [OtpVerifyResult].
class ApiAuthDataSource implements AuthDataSource, RemoteDataSource {
  ApiAuthDataSource(this._client);

  final ApiClient _client;

  @override
  Future<AuthSessionModel?> fetchCurrentSession(String accessToken) async {
    try {
      final Map<String, dynamic> json = await _client.getJson('/guest/auth/me');
      final Map<String, dynamic> data = _data(json);
      final Map<String, dynamic> guest =
          (data['guest'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
      return AuthSessionModel(
        accessToken: accessToken,
        phoneE164: guest['phone'] as String? ?? '',
        fullName: guest['name'] as String?,
        email: guest['email'] as String?,
      );
    } on UnauthorizedException {
      return null;
    } on DioException catch (e) {
      if (e.error is UnauthorizedException) return null;
      rethrow;
    }
  }

  @override
  Future<OtpChallengeModel> requestOtp(String phoneE164) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/auth/otp/request',
      body: <String, dynamic>{'phone': phoneE164},
    );
    return OtpChallengeModel.fromJson(_data(json));
  }

  @override
  Future<OtpChallengeModel> resendOtp({
    required String challengeId,
    required String phoneE164,
  }) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/auth/otp/resend',
      body: <String, dynamic>{'challenge_id': challengeId, 'phone': phoneE164},
    );
    return OtpChallengeModel.fromJson(_data(json));
  }

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String challengeId,
    required String phoneE164,
    required int attemptsRemaining,
    required String code,
  }) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/auth/otp/verify',
      body: <String, dynamic>{
        'challenge_id': challengeId,
        'phone': phoneE164,
        'code': code,
      },
    );
    final Map<String, dynamic> data = _data(json);

    switch (data['outcome'] as String?) {
      case 'authenticated':
        return OtpVerifyAccepted(AuthSessionModel.fromVerify(data));
      case 'locked_out':
        return const OtpVerifyLockedOut();
      case 'rejected':
      default:
        return OtpVerifyRejected(
          attemptsRemaining: (data['attempts_remaining'] as num?)?.toInt() ?? 0,
        );
    }
  }

  @override
  Future<AuthSessionModel> completeProfile({
    required String accessToken,
    required String phoneE164,
    required String fullName,
    required String email,
  }) async {
    // The token is already persisted by the repository, so AuthInterceptor
    // attaches it — no explicit header needed here.
    final Map<String, dynamic> json = await _client.patchJson(
      '/guest/profile',
      body: <String, dynamic>{'name': fullName, 'email': email},
    );
    final Map<String, dynamic> data = _data(json);
    final Map<String, dynamic> guest =
        (data['guest'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return AuthSessionModel(
      accessToken: accessToken,
      phoneE164: guest['phone'] as String? ?? phoneE164,
      fullName: guest['name'] as String?,
      email: guest['email'] as String?,
    );
  }

  @override
  Future<void> revokeSession() async {
    // AuthInterceptor attaches the still-stored bearer token.
    try {
      await _client.postJson('/guest/auth/logout');
    } on UnauthorizedException {
      // Already expired/revoked server-side — nothing left to revoke.
    } on DioException catch (e) {
      if (e.error is! UnauthorizedException) rethrow;
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> json) {
    final Object? data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw const UnknownException(message: 'Malformed auth response');
  }
}
