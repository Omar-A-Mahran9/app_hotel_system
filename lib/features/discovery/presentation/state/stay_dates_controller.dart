import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/stay_range.dart';
import '../../domain/validators/stay_dates_validator.dart';

/// The in-progress check-in / check-out selection on `16 · Stay dates &
/// available rooms`. Becomes a [StayRange] only once both dates are set and
/// valid; until then the "show available rooms" CTA stays disabled.
@immutable
class StayDatesDraft {
  const StayDatesDraft({this.checkIn, this.checkOut});

  final DateTime? checkIn;
  final DateTime? checkOut;

  bool get isEmpty => checkIn == null && checkOut == null;

  StayDatesError? errorAgainst(DateTime minDate) => StayDatesValidator.validate(
        checkIn: checkIn,
        checkOut: checkOut,
        minDate: minDate,
      );

  StayRange? rangeAgainst(DateTime minDate) => StayDatesValidator.toRange(
        checkIn: checkIn,
        checkOut: checkOut,
        minDate: minDate,
      );

  @override
  bool operator ==(Object other) =>
      other is StayDatesDraft &&
      other.checkIn == checkIn &&
      other.checkOut == checkOut;

  @override
  int get hashCode => Object.hash(checkIn, checkOut);
}

class StayDatesController extends Notifier<StayDatesDraft> {
  @override
  StayDatesDraft build() => const StayDatesDraft();

  /// Range-style selection: the first tap sets check-in, the second sets
  /// check-out (or restarts if it is not after check-in), a third tap starts
  /// over. Mirrors the calendar behaviour in the reference.
  void selectDay(DateTime day) {
    final DateTime picked = dateOnly(day);
    final StayDatesDraft current = state;

    if (current.checkIn == null || current.checkOut != null) {
      state = StayDatesDraft(checkIn: picked);
      return;
    }
    if (!picked.isAfter(current.checkIn!)) {
      state = StayDatesDraft(checkIn: picked);
      return;
    }
    state = StayDatesDraft(checkIn: current.checkIn, checkOut: picked);
  }

  void clear() => state = const StayDatesDraft();

  /// Seeds the draft from an existing range (used when returning to the picker
  /// to edit the dates).
  void setRange(StayRange range) => state = StayDatesDraft(
        checkIn: range.checkIn,
        checkOut: range.checkOut,
      );
}

final stayDatesControllerProvider =
    NotifierProvider<StayDatesController, StayDatesDraft>(
  StayDatesController.new,
);
