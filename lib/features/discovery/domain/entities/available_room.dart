import 'package:flutter/foundation.dart';

import 'money.dart';
import 'room_type_summary.dart';

/// A room type offered for a specific stay. The mobile app does not decide
/// authoritative availability — a later phase's Laravel API does — so this is a
/// dummy-data demonstration only.
@immutable
class AvailableRoom {
  const AvailableRoom({required this.roomType, required this.isAvailable});

  final RoomTypeSummary roomType;

  /// `false` for a room type the hotel lists but that is sold out for the stay —
  /// the card renders it greyed with a "not available" note.
  final bool isAvailable;

  Money get nightlyRate => roomType.nightlyRate;

  /// Price for the whole stay. Pure multiplication — no taxes or fees, which the
  /// design does not define at this step.
  Money stayTotal(int nights) => roomType.nightlyRate * nights;

  @override
  bool operator ==(Object other) =>
      other is AvailableRoom &&
      other.roomType == roomType &&
      other.isAvailable == isAvailable;

  @override
  int get hashCode => Object.hash(roomType, isAvailable);
}
