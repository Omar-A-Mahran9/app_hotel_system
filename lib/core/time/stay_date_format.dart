import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../features/discovery/domain/entities/stay_range.dart';

/// A compact "12 — 14 September" / "12 سبتمبر — 14 أكتوبر" range, matching the
/// Figma bookings list/detail boards. Falls back to including each month name
/// when the stay spans two different months.
String formatStayDateRange(Locale locale, StayRange stay) {
  final String tag = locale.toString();
  if (stay.checkIn.month == stay.checkOut.month) {
    final String month = DateFormat.MMMM(tag).format(stay.checkIn);
    return '${stay.checkIn.day} — ${stay.checkOut.day} $month';
  }
  final DateFormat dayMonth = DateFormat.MMMd(tag);
  return '${dayMonth.format(stay.checkIn)} — ${dayMonth.format(stay.checkOut)}';
}
