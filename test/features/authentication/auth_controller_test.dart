import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/di/core_providers.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_profile.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_state.dart';

import '../../support/auth_test_support.dart';

ProviderContainer _container({AuthSession? bootSession}) {
  final ProviderContainer container = ProviderContainer(
    overrides: authOverrides(bootSession: bootSession),
  );
  addTearDown(container.dispose);
  // Trigger the notifier so its restore future is scheduled before tests wait.
  container.read(authControllerProvider);
  return container;
}

void main() {
  test('starts unknown, then resolves to unauthenticated with no stored session',
      () async {
    final ProviderContainer container = _container();
    expect(container.read(authControllerProvider), isA<AuthUnknown>());

    await pumpEventQueue();
    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
  });

  test('a restored complete session resolves to authenticated', () async {
    final ProviderContainer container =
        _container(bootSession: completeSession());
    await pumpEventQueue();
    expect(container.read(authControllerProvider), isA<Authenticated>());
  });

  test('a restored session without a profile resolves to awaitingProfile',
      () async {
    final ProviderContainer container = _container(
      bootSession: const AuthSession(
        accessToken: 't',
        profile: GuestProfile(phone: kTestPhone),
      ),
    );
    await pumpEventQueue();
    expect(container.read(authControllerProvider), isA<AuthAwaitingProfile>());
  });

  test('onOtpVerified routes by profile completeness', () async {
    final ProviderContainer container = _container();
    await pumpEventQueue();
    final AuthController controller =
        container.read(authControllerProvider.notifier);

    controller.onOtpVerified(const AuthSession(
      accessToken: 't',
      profile: GuestProfile(phone: kTestPhone),
    ));
    expect(container.read(authControllerProvider), isA<AuthAwaitingProfile>());

    controller.onOtpVerified(completeSession());
    expect(container.read(authControllerProvider), isA<Authenticated>());
  });

  test('onProfileCompleted moves to authenticated', () async {
    final ProviderContainer container = _container();
    await pumpEventQueue();
    container
        .read(authControllerProvider.notifier)
        .onProfileCompleted(completeSession());
    expect(container.read(authControllerProvider), isA<Authenticated>());
  });

  test('signOut clears back to unauthenticated', () async {
    final ProviderContainer container =
        _container(bootSession: completeSession());
    await pumpEventQueue();
    await container.read(authControllerProvider.notifier).signOut();
    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
  });

  test('expireSession moves to sessionExpired and acknowledgeExpiry clears it',
      () async {
    final ProviderContainer container =
        _container(bootSession: completeSession());
    await pumpEventQueue();
    final AuthController controller =
        container.read(authControllerProvider.notifier);

    await controller.expireSession();
    expect(container.read(authControllerProvider), isA<AuthSessionExpired>());

    controller.acknowledgeExpiry();
    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
  });

  test('a rejected token (401) ends a signed-in session as expired', () async {
    final ProviderContainer container =
        _container(bootSession: completeSession());
    await pumpEventQueue();
    expect(container.read(authControllerProvider), isA<Authenticated>());

    container.read(sessionEventsProvider).reportTokenRejected();
    await pumpEventQueue();

    expect(container.read(authControllerProvider), isA<AuthSessionExpired>());
  });

  test('a rejected token while signed out changes nothing', () async {
    final ProviderContainer container = _container();
    await pumpEventQueue();

    container.read(sessionEventsProvider).reportTokenRejected();
    await pumpEventQueue();

    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
  });
}
