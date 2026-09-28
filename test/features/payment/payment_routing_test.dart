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
  test('the payment routes are registered alongside the earlier routes', () {
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
        AppRoutes.paymentReview,
        AppRoutes.paymentProcessing,
        AppRoutes.paymentResult,
        // earlier routes remain registered
        AppRoutes.reservationDetail,
        AppRoutes.roomSelectionReview,
        AppRoutes.discover,
        AppRoutes.welcome,
      ]),
    );
  });

  testWidgets('an unauthenticated deep link to payment goes to welcome',
      (WidgetTester tester) async {
    final c = await pumpApp(tester);
    c.read(appRouterProvider).go('/reservation/4821/payment');
    await tester.pumpAndSettle();
    expect(_location(c), AppRoutes.welcome);
  });
}
