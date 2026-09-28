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
  test('the reservation-detail route is registered alongside the earlier routes',
      () {
    final ProviderContainer c = ProviderContainer(overrides: authOverrides());
    addTearDown(c.dispose);
    final Iterable<String> paths = c
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .map((GoRoute r) => r.path);

    expect(
      paths,
      containsAll(<String>[
        AppRoutes.reservationDetail,
        // Phase 2/3 routes remain registered.
        AppRoutes.roomSelectionReview,
        AppRoutes.roomDetail,
        AppRoutes.availableRooms,
        AppRoutes.discover,
        // Phase 1 routes remain registered.
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.home,
      ]),
    );
  });

  testWidgets('an unauthenticated deep link to a reservation goes to welcome',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester);
    c.read(appRouterProvider).go('/reservation/4821');
    await tester.pumpAndSettle();
    expect(_location(c), AppRoutes.welcome);
  });
}
