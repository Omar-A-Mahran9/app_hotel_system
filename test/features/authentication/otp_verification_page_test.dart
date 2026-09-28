import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/auth_demo_config.dart';
import 'package:hotel_guest_app/features/authentication/presentation/widgets/otp_code_field.dart';

import '../../support/pump_app.dart';

Future<AppLocalizations> _openOtp(WidgetTester tester) async {
  await pumpSignIn(tester);
  final AppLocalizations en = await tester.l10n();
  await tester.enterText(find.byType(TextField), '0512345678');
  await tester.pump();
  await tester.tap(find.text(en.authPhoneSubmit));
  await tester.pumpAndSettle();
  return en;
}

void main() {
  testWidgets('renders the code field and the masked destination number',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openOtp(tester);
    expect(find.text(en.authOtpHeading), findsOneWidget);
    expect(find.byType(OtpCodeField), findsOneWidget);
    expect(find.text('+966 51 234 5678'), findsOneWidget);
  });

  testWidgets('a wrong code shows the incorrect-code banner with attempts left',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openOtp(tester);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();

    expect(find.text(en.authOtpErrorTitle), findsOneWidget);
    expect(find.text(en.authOtpErrorBody(2)), findsOneWidget);
    expect(find.text(en.authOtpChangeNumber), findsOneWidget);
  });

  testWidgets('three wrong codes lock the screen', (WidgetTester tester) async {
    final AppLocalizations en = await _openOtp(tester);

    for (var i = 0; i < 3; i++) {
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
    }

    expect(find.text(en.authOtpLockedTitle), findsOneWidget);
  });

  testWidgets('the correct code advances a first-time guest to the profile step',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openOtp(tester);

    await tester.enterText(
      find.byType(TextField),
      AuthDemoConfig.acceptedCode,
    );
    await tester.pumpAndSettle();

    expect(find.text(en.authProfileTitle), findsOneWidget);
  });

  testWidgets('resend is offered immediately when the cooldown is zero',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openOtp(tester);
    expect(find.text(en.authOtpResendAction), findsOneWidget);
  });
}
