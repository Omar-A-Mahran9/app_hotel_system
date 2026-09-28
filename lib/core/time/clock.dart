import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current wall-clock time, behind a provider so tests can pin "now".
///
/// Business data must never come from `DateTime.now()` (coding_rules.md,
/// phase brief §13); the only legitimate use is UI framing such as the first
/// selectable day in a date picker. Widgets read this provider for that so the
/// value is deterministic under test.
final clockProvider = Provider<DateTime Function()>((Ref ref) => DateTime.now);

extension ClockX on WidgetRef {
  /// Today as a date-only value (local calendar day).
  DateTime today() {
    final DateTime now = read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }
}
