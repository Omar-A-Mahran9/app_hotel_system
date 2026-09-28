import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/problem_reports/data/datasources/dummy_problem_report_data_source.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import 'problem_reports_test_support.dart';

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

Future<ProviderContainer> _openList(
  WidgetTester tester,
  String reservationId, {
  Locale? locale,
}) async {
  final ProviderContainer c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
  );
  c.read(appRouterProvider).go('/reservation/$reservationId/reports');
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('an empty history shows the empty state with a new-report CTA',
      (WidgetTester tester) async {
    final AppLocalizations en = await _l10n('en');
    final String rid =
        reservationIdForProblemScenario(DummyProblemReportScenario.none);

    await _openList(tester, rid);

    expect(find.text(en.myReportsEmptyTitle), findsOneWidget);
    expect(find.widgetWithText(FilledButton, en.newReportCta), findsOneWidget);
  });

  testWidgets(
      'a reservation with prior reports lists them with category and status',
      (WidgetTester tester) async {
    final AppLocalizations en = await _l10n('en');
    final String rid = reservationIdForProblemScenario(
      DummyProblemReportScenario.onePriorInProgress,
    );

    await _openList(tester, rid);

    expect(find.text(en.myReportsTitle), findsWidgets);
    expect(find.text(en.reportCategoryAcHeating), findsOneWidget);
    expect(find.text(en.reportStatusInProgress), findsOneWidget);
  });

  testWidgets('tapping a report opens its track/detail screen',
      (WidgetTester tester) async {
    final AppLocalizations en = await _l10n('en');
    final String rid = reservationIdForProblemScenario(
      DummyProblemReportScenario.onePriorResolved,
    );

    await _openList(tester, rid);
    expect(find.text(en.reportCategoryPlumbingWater), findsOneWidget);

    await tester.tap(find.text(en.reportCategoryPlumbingWater).first);
    await tester.pumpAndSettle();

    expect(find.text(en.reportDetailTitle), findsWidgets);
    expect(find.text(en.reportStatusResolved), findsWidgets);
  });

  testWidgets('the "my reports" entry from the category picker opens the list',
      (WidgetTester tester) async {
    final AppLocalizations en = await _l10n('en');
    final String rid =
        reservationIdForProblemScenario(DummyProblemReportScenario.none);

    final ProviderContainer c = await pumpApp(tester, bootSession: completeSession());
    c.read(appRouterProvider).go('/reservation/$rid/report');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, en.myReportsTitle));
    await tester.pumpAndSettle();

    expect(find.text(en.myReportsEmptyTitle), findsOneWidget);
  });

  testWidgets('the reports list renders right-to-left in Arabic',
      (WidgetTester tester) async {
    final AppLocalizations ar = await _l10n('ar');
    final String rid = reservationIdForProblemScenario(
      DummyProblemReportScenario.onePriorInProgress,
    );

    await _openList(tester, rid, locale: arabic);

    expect(find.text(ar.myReportsTitle), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text(ar.myReportsTitle).first)),
      TextDirection.rtl,
    );
  });
}
