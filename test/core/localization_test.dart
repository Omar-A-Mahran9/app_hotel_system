import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/app.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/localization/locale_controller.dart';
import 'package:hotel_guest_app/core/localization/supported_locales.dart';

import '../support/auth_test_support.dart';

void main() {
  test('every English key has an Arabic translation', () async {
    final AppLocalizations en =
        await AppLocalizations.delegate.load(const Locale('en'));
    final AppLocalizations ar =
        await AppLocalizations.delegate.load(const Locale('ar'));

    expect(en.appName, isNotEmpty);
    expect(ar.appName, isNotEmpty);
    expect(ar.actionRetry, isNot(equals(en.actionRetry)));
    expect(ar.appTagline, contains('احجز'));
  });

  test('supported locales list Arabic and English', () {
    expect(SupportedLocales.all, containsAll(<Locale>[
      const Locale('ar'),
      const Locale('en'),
    ]));
    expect(SupportedLocales.isRtl(const Locale('ar')), isTrue);
    expect(SupportedLocales.isRtl(const Locale('en')), isFalse);
  });

  testWidgets('switching to Arabic flips the app to RTL', (WidgetTester tester) async {
    final container = ProviderContainer(overrides: authOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HotelGuestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.ltr);

    container.read(localeControllerProvider.notifier).set(SupportedLocales.arabic);
    await tester.pumpAndSettle();

    expect(Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.rtl);

    final AppLocalizations ar =
        await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(ar.entryHeadline), findsOneWidget);
  });
}
