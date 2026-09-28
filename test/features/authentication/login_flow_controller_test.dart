import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/auth_demo_config.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_state.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/login_flow_controller.dart';

import '../../support/auth_test_support.dart';

ProviderContainer _container() {
  final ProviderContainer container =
      ProviderContainer(overrides: authOverrides());
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts on the phone step', () {
    expect(_container().read(loginFlowControllerProvider), isA<LoginPhoneStep>());
  });

  test('submitPhone advances to the OTP step with a fresh challenge', () async {
    final ProviderContainer container = _container();
    await container
        .read(loginFlowControllerProvider.notifier)
        .submitPhone(kTestPhone);

    final LoginFlowState state = container.read(loginFlowControllerProvider);
    expect(state, isA<LoginOtpStep>());
    expect((state as LoginOtpStep).attemptsRemaining,
        AuthDemoConfig.maxAttempts);
  });

  test('a wrong code moves to rejected and counts attempts down', () async {
    final ProviderContainer container = _container();
    final LoginFlowController flow =
        container.read(loginFlowControllerProvider.notifier);
    await flow.submitPhone(kTestPhone);

    await flow.submitCode('000000');
    LoginOtpStep step =
        container.read(loginFlowControllerProvider) as LoginOtpStep;
    expect(step.status, OtpEntryStatus.rejected);
    expect(step.attemptsRemaining, 2);

    await flow.submitCode('000000');
    step = container.read(loginFlowControllerProvider) as LoginOtpStep;
    expect(step.attemptsRemaining, 1);
  });

  test('exhausting the attempts locks the step', () async {
    final ProviderContainer container = _container();
    final LoginFlowController flow =
        container.read(loginFlowControllerProvider.notifier);
    await flow.submitPhone(kTestPhone);
    await flow.submitCode('000000');
    await flow.submitCode('000000');
    await flow.submitCode('000000');

    final LoginOtpStep step =
        container.read(loginFlowControllerProvider) as LoginOtpStep;
    expect(step.status, OtpEntryStatus.lockedOut);
  });

  test('a correct code notifies the auth controller', () async {
    final ProviderContainer container = _container();
    final LoginFlowController flow =
        container.read(loginFlowControllerProvider.notifier);
    container.read(authControllerProvider.notifier);
    await pumpEventQueue();

    await flow.submitPhone(kTestPhone);
    await flow.submitCode(AuthDemoConfig.acceptedCode);

    // First-time guest → awaiting profile.
    expect(container.read(authControllerProvider), isA<AuthAwaitingProfile>());
  });

  test('resendCode issues a new challenge and clears the locked state',
      () async {
    final ProviderContainer container = _container();
    final LoginFlowController flow =
        container.read(loginFlowControllerProvider.notifier);
    await flow.submitPhone(kTestPhone);
    await flow.submitCode('000000');
    await flow.submitCode('000000');
    await flow.submitCode('000000');

    await flow.resendCode();
    final LoginOtpStep step =
        container.read(loginFlowControllerProvider) as LoginOtpStep;
    expect(step.status, OtpEntryStatus.editing);
    expect(step.attemptsRemaining, AuthDemoConfig.maxAttempts);
  });

  test('submitPhone exposes an in-progress submission while in flight',
      () async {
    final ProviderContainer container = _container();
    final LoginFlowController flow =
        container.read(loginFlowControllerProvider.notifier);

    final Future<void> pending = flow.submitPhone(kTestPhone);
    final LoginPhoneStep step =
        container.read(loginFlowControllerProvider) as LoginPhoneStep;
    expect(step.submission.isInProgress, isTrue);
    await pending;
  });

  test('submitCode exposes the verifying status while in flight', () async {
    final ProviderContainer container = _container();
    final LoginFlowController flow =
        container.read(loginFlowControllerProvider.notifier);
    await flow.submitPhone(kTestPhone);

    final Future<void> pending = flow.submitCode('000000');
    final LoginOtpStep step =
        container.read(loginFlowControllerProvider) as LoginOtpStep;
    expect(step.status, OtpEntryStatus.verifying);
    await pending;
  });

  test('reset returns to the phone step', () async {
    final ProviderContainer container = _container();
    final LoginFlowController flow =
        container.read(loginFlowControllerProvider.notifier);
    await flow.submitPhone(kTestPhone);
    flow.reset();
    expect(container.read(loginFlowControllerProvider), isA<LoginPhoneStep>());
  });
}
