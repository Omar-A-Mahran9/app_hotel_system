import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_profile.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

String _location(ProviderContainer container) {
  final GoRouter router = container.read(appRouterProvider);
  return router.routerDelegate.currentConfiguration.uri.path;
}

void main() {
  test('every Phase 1 route is registered', () {
    final ProviderContainer container =
        ProviderContainer(overrides: authOverrides());
    addTearDown(container.dispose);
    final Iterable<String> paths = container
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .map((GoRoute r) => r.path);
    expect(
      paths,
      containsAll(<String>[
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.otp,
        AppRoutes.completeProfile,
        AppRoutes.sessionExpired,
        AppRoutes.home,
      ]),
    );
  });

  testWidgets('unauthenticated boot redirects to the entry screen',
      (WidgetTester tester) async {
    final ProviderContainer container = await pumpApp(tester);
    expect(_location(container), AppRoutes.welcome);
  });

  testWidgets('authenticated boot redirects to discover',
      (WidgetTester tester) async {
    final ProviderContainer container =
        await pumpApp(tester, bootSession: completeSession());
    expect(_location(container), AppRoutes.discover);
  });

  testWidgets('an awaiting-profile session is forced onto the profile route',
      (WidgetTester tester) async {
    final ProviderContainer container = await pumpApp(
      tester,
      bootSession: const AuthSession(
        accessToken: 't',
        profile: GuestProfile(phone: kTestPhone),
      ),
    );
    expect(_location(container), AppRoutes.completeProfile);
  });

  testWidgets(
      'signing out from the account tab (not public) lands on sign-in',
      (WidgetTester tester) async {
    final ProviderContainer container =
        await pumpApp(tester, bootSession: completeSession());
    final AppLocalizations en = await tester.l10n();

    // Sign-out lives on the Account tab (mobile/docs/design-system.md), which
    // — unlike `/discover` — is not part of the deferred-auth public surface.
    // The router treats a signed-out `/account` as an explicit sign-in entry
    // point, so the guest lands on the phone sign-in screen.
    container.read(appRouterProvider).goNamed(AppRoutes.accountName);
    await tester.pumpAndSettle();

    // Account row → `PROFILE_Logout_Confirm_Overlay` → confirm.
    await tester.tap(find.text(en.authSignOut));
    await tester.pumpAndSettle();
    expect(find.text(en.profileLogoutConfirmTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.authSignOut));
    await tester.pumpAndSettle();

    expect(_location(container), AppRoutes.signIn);
  });

  testWidgets('an expired session is forced onto the session-expired route',
      (WidgetTester tester) async {
    final ProviderContainer container =
        await pumpApp(tester, bootSession: completeSession());
    await container.read(authControllerProvider.notifier).expireSession();
    await tester.pumpAndSettle();
    expect(_location(container), AppRoutes.sessionExpired);
  });
}
