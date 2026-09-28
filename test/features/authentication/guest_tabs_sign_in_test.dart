import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';

import '../../support/pump_app.dart';

/// A signed-out guest opening the Bookings / Services tab sees a "sign in to
/// continue" prompt (not the welcome screen); signing in returns them to the
/// same tab (docs/mobile-deferred-auth.md).

String _path(ProviderContainer c) =>
    c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  final Map<String, String Function(AppLocalizations)> tabs =
      <String, String Function(AppLocalizations)>{
    AppRoutes.bookingsName: (AppLocalizations l) => l.guestSignInBookingsBody,
    AppRoutes.stayHomeName: (AppLocalizations l) => l.guestSignInServicesBody,
  };

  for (final MapEntry<String, String Function(AppLocalizations)> tab
      in tabs.entries) {
    testWidgets('guest on ${tab.key} is prompted to sign in and returns there',
        (WidgetTester tester) async {
      final AppLocalizations en =
          await AppLocalizations.delegate.load(const Locale('en'));
      final ProviderContainer c = await pumpApp(tester);
      c.read(appRouterProvider).goNamed(tab.key);
      await tester.pumpAndSettle();

      final String tabPath = _path(c);
      expect(tabPath, isNot(AppRoutes.welcome));
      expect(find.text(en.guestSignInRequiredTitle), findsOneWidget);
      expect(find.text(tab.value(en)), findsOneWidget);

      await tester.tap(find.text(en.guestSignInAction));
      await tester.pumpAndSettle();
      expect(_path(c), AppRoutes.signIn);

      await tester.enterText(find.byType(TextField), '0512345678');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, en.authPhoneSubmit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      final Finder fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Mahmoud Nabil');
      await tester.enterText(fields.at(1), 'mahmoud@example.com');
      await tester.pump();
      await tester.tap(find.text(en.authProfileSubmit));
      await tester.pumpAndSettle();

      expect(_path(c), tabPath);
      expect(find.text(en.guestSignInRequiredTitle), findsNothing);
    });
  }
}
