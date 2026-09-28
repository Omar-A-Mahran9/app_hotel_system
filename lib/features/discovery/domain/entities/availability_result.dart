import 'package:flutter/foundation.dart';

import 'available_room.dart';
import 'guest_party.dart';
import 'stay_range.dart';

/// The rooms a hotel can offer for a given stay and party.
///
/// This is a dummy-data view only. When the Laravel availability API lands it
/// replaces the data source that builds this, with no change to the entity.
@immutable
class AvailabilityResult {
  const AvailabilityResult({
    required this.hotelId,
    required this.stay,
    required this.party,
    required this.rooms,
  });

  final String hotelId;
  final StayRange stay;
  final GuestParty party;
  final List<AvailableRoom> rooms;

  /// At least one room the party can actually book.
  bool get hasBookableRoom => rooms.any((AvailableRoom r) => r.isAvailable);

  /// Rooms exist for the hotel but every one is sold out for this stay — the
  /// list still renders them greyed rather than showing the no-results screen.
  bool get isSoldOut => rooms.isNotEmpty && !hasBookableRoom;

  int get bookableCount =>
      rooms.where((AvailableRoom r) => r.isAvailable).length;

  @override
  bool operator ==(Object other) =>
      other is AvailabilityResult &&
      other.hotelId == hotelId &&
      other.stay == stay &&
      other.party == party &&
      listEquals(other.rooms, rooms);

  @override
  int get hashCode =>
      Object.hash(hotelId, stay, party, Object.hashAll(rooms));
}
