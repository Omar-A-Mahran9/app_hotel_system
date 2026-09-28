import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/auth_demo_config.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/dummy_auth_data_source.dart';
import 'package:hotel_guest_app/features/authentication/data/models/auth_models.dart';

void main() {
  const DummyAuthDataSource source = DummyAuthDataSource();
  const String phone = '+966512345678';

  test('requestOtp returns a deterministic challenge', () async {
    final OtpChallengeModel a = await source.requestOtp(phone);
    final OtpChallengeModel b = await source.requestOtp(phone);
    expect(a.challengeId, b.challengeId);
    expect(a.codeLength, AuthDemoConfig.codeLength);
    expect(a.attemptsRemaining, AuthDemoConfig.maxAttempts);
  });

  test('requestOtp rejects an implausible number', () async {
    expect(
      () => source.requestOtp('12345'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('verifyOtp accepts the demo code for a first-time guest', () async {
    final OtpVerifyResult result = await source.verifyOtp(
      challengeId: 'c1',
      phoneE164: phone,
      attemptsRemaining: 3,
      code: AuthDemoConfig.acceptedCode,
    );
    expect(result, isA<OtpVerifyAccepted>());
    final AuthSessionModel session = (result as OtpVerifyAccepted).session;
    expect(session.accessToken, isNotEmpty);
    expect(session.fullName, isNull, reason: 'new guest still owes a profile');
  });

  test('verifyOtp signs a returning guest straight in', () async {
    final OtpVerifyResult result = await source.verifyOtp(
      challengeId: 'c1',
      phoneE164: AuthDemoConfig.returningGuests.first,
      attemptsRemaining: 3,
      code: AuthDemoConfig.acceptedCode,
    );
    final AuthSessionModel session = (result as OtpVerifyAccepted).session;
    expect(session.fullName, isNotNull);
    expect(session.email, isNotNull);
  });

  test('a wrong code decrements the remaining attempts', () async {
    final OtpVerifyResult result = await source.verifyOtp(
      challengeId: 'c1',
      phoneE164: phone,
      attemptsRemaining: 3,
      code: '000000',
    );
    expect(result, isA<OtpVerifyRejected>());
    expect((result as OtpVerifyRejected).attemptsRemaining, 2);
  });

  test('a wrong code on the last attempt locks the challenge', () async {
    final OtpVerifyResult result = await source.verifyOtp(
      challengeId: 'c1',
      phoneE164: phone,
      attemptsRemaining: 1,
      code: '000000',
    );
    expect(result, isA<OtpVerifyLockedOut>());
  });

  test('verifyOtp with no attempts left is always locked out', () async {
    final OtpVerifyResult result = await source.verifyOtp(
      challengeId: 'c1',
      phoneE164: phone,
      attemptsRemaining: 0,
      code: AuthDemoConfig.acceptedCode,
    );
    expect(result, isA<OtpVerifyLockedOut>());
  });

  test('completeProfile echoes the trimmed details', () async {
    final AuthSessionModel session = await source.completeProfile(
      accessToken: 'tok',
      phoneE164: phone,
      fullName: '  Mahmoud Nabil  ',
      email: '  m@example.com ',
    );
    expect(session.fullName, 'Mahmoud Nabil');
    expect(session.email, 'm@example.com');
  });

  test('completeProfile rejects blank input', () async {
    expect(
      () => source.completeProfile(
        accessToken: 'tok',
        phoneE164: phone,
        fullName: '',
        email: '',
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}
