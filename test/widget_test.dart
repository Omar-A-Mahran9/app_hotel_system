import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/app.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';

import 'support/auth_test_support.dart';

void main() {
  testWidgets('an unauthenticated cold start lands on the entry screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: authOverrides(), child: const HotelGuestApp()),
    );
    await tester.pumpAndSettle();

    final AppLocalizations en =
        await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(en.entryHeadline), findsOneWidget);
    expect(find.text(en.entryStartAction), findsOneWidget);
  });

  testWidgets('an authenticated cold start lands on the discover screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: authOverrides(bootSession: completeSession()),
        child: const HotelGuestApp(),
      ),
    );
    await tester.pumpAndSettle();

    final AppLocalizations en =
        await AppLocalizations.delegate.load(const Locale('en'));
    // Phase 2: discover is the authenticated landing (was the Phase 0 preview).
    expect(find.text(en.discoverExploreHotels), findsOneWidget);
  });
}
