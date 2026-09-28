import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/stay_range_calendar.dart';

/// Taps a day inside the [StayRangeCalendar], scrolling it into view first.
///
/// The design-system type scale uses Arabic (loose) line-heights, so on the
/// 800×600 test viewport the stay-dates header leaves the calendar's first rows
/// partly under the sticky footer. `ensureVisible` no-ops when a target is even
/// partly visible, so drive the scroll explicitly.
Future<void> tapCalendarDay(WidgetTester tester, String day) async {
  final Finder cell = find
      .descendant(
        of: find.byType(StayRangeCalendar),
        matching: find.text(day),
      )
      .first;
  await tester.dragUntilVisible(
    cell,
    find.byType(StayRangeCalendar),
    const Offset(0, -80),
  );
  await tester.pumpAndSettle();
  await tester.tap(cell, warnIfMissed: false);
  await tester.pumpAndSettle();
}
