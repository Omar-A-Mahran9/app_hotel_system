// Public named parameters (`dataSource`, `tokenStore`) map to private fields; an
// initializing formal would leak the leading underscore into every call site.
// ignore_for_file: prefer_initializing_formals

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/security/token_store.dart';
import '../../domain/entities/guest_phone.dart';
import '../../domain/entities/guest_profile.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../models/auth_models.dart';

/// Coordinates the auth data source, the token store and the in-memory session.
///
/// Which [AuthDataSource] it holds (dummy vs API) is decided by DI, not here
/// (feature_guide.md Step 5). Every data-layer error is mapped to a `Failure`
/// via [ErrorMapper] so the presentation layer only handles the user-safe type.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthDataSource dataSource,
    required TokenStore tokenStore,
  })  : _dataSource = dataSource,
        _tokenStore = tokenStore;

  final AuthDataSource _dataSource;
  final TokenStore _tokenStore;

  AuthSession? _current;

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      final String? token = await _tokenStore.readAccessToken();
      if (token == null) {
        _current = null;
        return null;
      }
      if (_current?.accessToken == token) return _current;
      // A token exists but the in-memory session is gone (cold start). Rebuild
      // it from the backend `me` endpoint (Slice 0); a rejected token clears.
      final AuthSessionModel? model =
          await _dataSource.fetchCurrentSession(token);
      if (model == null) {
        await _tokenStore.clear();
        _current = null;
        return null;
      }
      final AuthSession restored = _toSession(
        model,
        fallbackPhone: GuestPhone.fromE164(model.phoneE164),
      );
      _current = restored;
      return restored;
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }

  @override
  Future<OtpChallenge> requestOtp(GuestPhone phone) =>
      _guard(() async => _toChallenge(
            await _dataSource.requestOtp(phone.e164),
            phone,
          ));

  @override
  Future<OtpChallenge> resendOtp(OtpChallenge challenge) =>
      _guard(() async => _toChallenge(
            await _dataSource.resendOtp(
              challengeId: challenge.challengeId,
              phoneE164: challenge.phone.e164,
            ),
            challenge.phone,
          ));

  @override
  Future<OtpVerification> verifyOtp({
    required OtpChallenge challenge,
    required String code,
  }) =>
      _guard(() async {
        final OtpVerifyResult result = await _dataSource.verifyOtp(
          challengeId: challenge.challengeId,
          phoneE164: challenge.phone.e164,
          attemptsRemaining: challenge.attemptsRemaining,
          code: code,
        );
        switch (result) {
          case OtpVerifyAccepted(:final AuthSessionModel session):
            final AuthSession authed =
                _toSession(session, fallbackPhone: challenge.phone);
            await _persist(authed);
            return OtpVerification.authenticated(authed);
          case OtpVerifyRejected(:final int attemptsRemaining):
            return OtpVerification.rejected(
              challenge.copyWith(attemptsRemaining: attemptsRemaining),
            );
          case OtpVerifyLockedOut():
            return OtpVerification.lockedOut(
              challenge.copyWith(attemptsRemaining: 0),
            );
        }
      });

  @override
  Future<AuthSession> completeProfile({
    required AuthSession session,
    required String fullName,
    required String email,
  }) =>
      _guard(() async {
        final AuthSessionModel model = await _dataSource.completeProfile(
          accessToken: session.accessToken,
          phoneE164: session.profile.phone.e164,
          fullName: fullName,
          email: email,
        );
        final AuthSession updated =
            _toSession(model, fallbackPhone: session.profile.phone);
        await _persist(updated);
        return updated;
      });

  @override
  Future<void> signOut() async {
    Object? revokeError;
    try {
      if (await _tokenStore.readAccessToken() != null) {
        await _dataSource.revokeSession();
      }
    } catch (error) {
      // Deliberately not rethrown before the local clear: a sign-out must
      // never leave the guest signed in on this device because the network
      // was down. Surfaced after clearing so callers can still log it.
      revokeError = error;
    }
    await clearLocalSession();
    if (revokeError != null) throw ErrorMapper.toFailure(revokeError);
  }

  @override
  Future<void> clearLocalSession() async {
    try {
      _current = null;
      await _tokenStore.clear();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }

  Future<void> _persist(AuthSession session) async {
    _current = session;
    await _tokenStore.writeAccessToken(session.accessToken);
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }

  OtpChallenge _toChallenge(OtpChallengeModel model, GuestPhone phone) =>
      OtpChallenge(
        challengeId: model.challengeId,
        phone: phone,
        codeLength: model.codeLength,
        attemptsRemaining: model.attemptsRemaining,
      );

  AuthSession _toSession(
    AuthSessionModel model, {
    required GuestPhone fallbackPhone,
  }) {
    return AuthSession(
      accessToken: model.accessToken,
      profile: GuestProfile(
        phone: fallbackPhone,
        fullName: model.fullName,
        email: model.email,
      ),
    );
  }
}
