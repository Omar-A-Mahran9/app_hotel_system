import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/theme/theme_controller.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/payment/presentation/pages/payment_review_page.dart';

import '../../support/auth_test_support.dart';
import '../../support/calendar_test_support.dart';
import '../../support/pump_app.dart';

void main() {
  testWidgets('the booking summary + payment screens render in dark mode',
      (WidgetTester tester) async {
    final ProviderContainer container = await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: <Override>[
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 1)),
      ],
    );
    container.read(themeModeControllerProvider.notifier).set(ThemeMode.dark);
    await tester.pumpAndSettle();

    final AppLocalizations en =
        await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text('The Oasis Hotel').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.hotelBookNow));
    await tester.pumpAndSettle();
    await tapCalendarDay(tester, '6');
    await tapCalendarDay(tester, '8');
    await tester.tap(find.widgetWithText(FilledButton, en.stayDatesShowRooms));
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(OutlinedButton, en.roomViewDetails).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.roomSelectThisRoom));
    await tester.pumpAndSettle();

    expect(find.text(en.bookingProceedToPayment), findsOneWidget);

    await tester
        .tap(find.widgetWithText(FilledButton, en.bookingProceedToPayment));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentReviewPage), findsOneWidget);
    expect(find.text(en.paymentReviewTitle), findsOneWidget);
    // Dark theme is actually applied.
    final ThemeData theme = Theme.of(
      tester.element(find.text(en.paymentReviewTitle)),
    );
    expect(theme.brightness, Brightness.dark);

    expect(tester.takeException(), isNull);
  });
}
