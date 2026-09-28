import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_profile.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

AuthSession _incompleteSession() => const AuthSession(
      accessToken: 't',
      profile: GuestProfile(phone: kTestPhone),
    );

void main() {
  testWidgets('an awaiting-profile session lands on the details form',
      (WidgetTester tester) async {
    await pumpApp(tester, bootSession: _incompleteSession());
    final AppLocalizations en = await tester.l10n();

    expect(find.text(en.authProfileTitle), findsOneWidget);
    expect(find.text(en.authProfileBannerTitle), findsOneWidget);
  });

  testWidgets('submitting blank fields shows validation and does not advance',
      (WidgetTester tester) async {
    await pumpApp(tester, bootSession: _incompleteSession());
    final AppLocalizations en = await tester.l10n();

    await tester.tap(find.text(en.authProfileSubmit));
    await tester.pump();

    expect(find.text(en.authProfileNameInvalid), findsOneWidget);
    expect(find.text(en.authProfileTitle), findsOneWidget);
  });

  testWidgets('valid details complete the profile and open the discover screen',
      (WidgetTester tester) async {
    await pumpApp(tester, bootSession: _incompleteSession());
    final AppLocalizations en = await tester.l10n();

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Mahmoud Nabil');
    await tester.enterText(fields.at(1), 'mahmoud@example.com');
    await tester.pump();

    await tester.tap(find.text(en.authProfileSubmit));
    await tester.pumpAndSettle();

    expect(find.text(en.discoverExploreHotels), findsOneWidget);
  });

  testWidgets('an invalid email is rejected locally',
      (WidgetTester tester) async {
    await pumpApp(tester, bootSession: _incompleteSession());
    final AppLocalizations en = await tester.l10n();

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Mahmoud Nabil');
    await tester.enterText(fields.at(1), 'bad-email');
    await tester.pump();
    await tester.tap(find.text(en.authProfileSubmit));
    await tester.pump();

    expect(find.text(en.authProfileEmailInvalid), findsOneWidget);
  });
}
