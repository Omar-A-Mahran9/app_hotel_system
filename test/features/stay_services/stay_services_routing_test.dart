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
  test('the stay-services routes are registered alongside earlier routes', () {
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
        AppRoutes.stayServices,
        AppRoutes.serviceDetail,
        AppRoutes.serviceOrders,
        AppRoutes.serviceOrderDetail,
        AppRoutes.reservationDetail,
        AppRoutes.discover,
      ]),
    );
  });

  testWidgets('an unauthenticated deep link to services goes to welcome',
      (WidgetTester tester) async {
    final c = await pumpApp(tester);
    c.read(appRouterProvider).go('/reservation/4821/services');
    await tester.pumpAndSettle();
    expect(_location(c), AppRoutes.welcome);
  });
}
