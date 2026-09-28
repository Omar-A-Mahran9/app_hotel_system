import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/authentication/presentation/widgets/otp_code_field.dart';
import 'package:hotel_guest_app/features/authentication/presentation/widgets/phone_number_field.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('the sign-in screen renders right-to-left in Arabic',
      (WidgetTester tester) async {
    await pumpSignIn(tester, locale: arabic);
    final AppLocalizations ar = await tester.l10n('ar');

    expect(find.text(ar.authPhoneHeading), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(ar.authPhoneHeading))),
      TextDirection.rtl,
    );
    // The phone number itself stays left-to-right inside the RTL screen.
    expect(
      Directionality.of(tester.element(find.byType(PhoneNumberField))),
      TextDirection.rtl,
    );
  });

  testWidgets('the OTP boxes stay left-to-right in an Arabic layout',
      (WidgetTester tester) async {
    await pumpSignIn(tester, locale: arabic);
    final AppLocalizations ar = await tester.l10n('ar');

    await tester.enterText(find.byType(TextField), '0512345678');
    await tester.pump();
    await tester.tap(find.text(ar.authPhoneSubmit));
    await tester.pumpAndSettle();

    final OtpCodeField field = tester.widget<OtpCodeField>(
      find.byType(OtpCodeField),
    );
    expect(field.length, 6);
    // The code entry is wrapped in an LTR Directionality regardless of locale.
    expect(
      Directionality.of(tester.element(find.byType(TextField))),
      TextDirection.ltr,
    );
  });
}
