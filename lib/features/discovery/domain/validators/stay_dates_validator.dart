import '../entities/stay_range.dart';

/// Why a check-in / check-out selection is not yet a valid [StayRange].
enum StayDatesError {
  /// One or both dates are missing.
  incomplete,

  /// Check-out is on or before check-in.
  checkOutNotAfterCheckIn,

  /// Check-in is earlier than the first selectable day.
  checkInInPast,
}

/// Validates a stay-date selection. Pure — the caller passes the "today" it
/// wants enforced (from `clockProvider` in the app, a fixed date in tests).
abstract final class StayDatesValidator {
  static StayDatesError? validate({
    required DateTime? checkIn,
    required DateTime? checkOut,
    DateTime? minDate,
  }) {
    if (checkIn == null || checkOut == null) return StayDatesError.incomplete;

    final DateTime inDay = dateOnly(checkIn);
    final DateTime outDay = dateOnly(checkOut);

    if (minDate != null && inDay.isBefore(dateOnly(minDate))) {
      return StayDatesError.checkInInPast;
    }
    if (!outDay.isAfter(inDay)) return StayDatesError.checkOutNotAfterCheckIn;
    return null;
  }

  /// Builds the range, or returns `null` when the selection is invalid.
  static StayRange? toRange({
    required DateTime? checkIn,
    required DateTime? checkOut,
    DateTime? minDate,
  }) {
    if (validate(checkIn: checkIn, checkOut: checkOut, minDate: minDate) != null) {
      return null;
    }
    return StayRange(checkIn: checkIn!, checkOut: checkOut!);
  }
}
