import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

String _location(ProviderContainer c) =>
    c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  test('the check-in / access routes are registered alongside earlier routes',
      () {
    final c = ProviderContainer(overrides: authOverrides());
    addTearDown(c.dispose);
    final paths = c
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .map((GoRoute r) => r.path);

    expect(
      paths,
      containsAll(<String>[
        AppRoutes.checkIn,
        AppRoutes.checkInProcessing,
        AppRoutes.digitalAccess,
        // earlier routes remain registered
        AppRoutes.paymentReview,
        AppRoutes.reservationDetail,
        AppRoutes.discover,
        AppRoutes.welcome,
      ]),
    );
  });

  testWidgets('an unauthenticated deep link to check-in goes to welcome',
      (WidgetTester tester) async {
    final c = await pumpApp(tester);
    c.read(appRouterProvider).go('/reservation/4821/check-in');
    await tester.pumpAndSettle();
    expect(_location(c), AppRoutes.welcome);
  });

  testWidgets('an unauthenticated deep link to access goes to welcome',
      (WidgetTester tester) async {
    final c = await pumpApp(tester);
    c.read(appRouterProvider).go('/reservation/4821/access');
    await tester.pumpAndSettle();
    expect(_location(c), AppRoutes.welcome);
  });
}
