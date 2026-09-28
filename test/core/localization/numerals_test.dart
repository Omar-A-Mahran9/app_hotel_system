import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/l10n.dart';
import 'package:hotel_guest_app/core/localization/numerals.dart';
import 'package:hotel_guest_app/core/widgets/money_text.dart';

void main() {
  const AppLocalizationsWithNumeralsDelegate delegate =
      AppLocalizationsWithNumeralsDelegate();

  test('localizeDigits converts only in Arabic', () {
    expect(localizeDigits('9:43 م', 'ar'), '٩:٤٣ م');
    expect(localizeDigits('9:43 PM', 'en'), '9:43 PM');
    expect(localizeDigits('no digits', 'ar'), 'no digits');
  });

  test('Arabic counts and points use Arabic-Indic digits', () async {
    final AppLocalizations ar = await delegate.load(const Locale('ar'));
    expect(ar.stayNights(3), '٣ ليالٍ');
    expect(ar.stayNights(2), 'ليلتان');
    expect(ar.loyaltyPointsValue(1240), '١٢٤٠ نقطة');
    expect(ar.roomsAvailableCount(8), contains('٨'));
  });

  test('English stays Western', () async {
    final AppLocalizations en = await delegate.load(const Locale('en'));
    expect(en.stayNights(3), '3 nights');
    expect(en.loyaltyPointsValue(1240), '1240 pts');
  });

  test('money, ratings and review counts are not converted', () async {
    final AppLocalizations ar = await delegate.load(const Locale('ar'));
    expect(ar.priceRangeValue(100, 900), isNot(contains('٩')));
    expect(ar.hotelReviewCount(217), contains('217'));
  });

  testWidgets('MoneyText keeps Western digits in Arabic', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: <Locale>[Locale('ar'), Locale('en')],
        localizationsDelegates: AppLocalizationsWithNumeralsDelegate.delegates,
        home: Scaffold(body: MoneyText(945)),
      ),
    );
    expect(find.textContaining('945'), findsOneWidget);
  });
}
