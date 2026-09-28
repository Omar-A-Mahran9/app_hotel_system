import 'package:flutter/foundation.dart';

import 'guest_party.dart';
import 'stay_range.dart';

/// The exact criteria an availability lookup was made for: a hotel, a stay and a
/// party.
///
/// Availability, and any room selected from it, is only meaningful for the
/// request it came from. Controllers tag their result with the request that
/// produced it so the UI can tell when a shown result (or a selected room) has
/// gone stale because the guest changed dates, guests or hotel.
@immutable
class AvailabilityRequest {
  const AvailabilityRequest({
    required this.hotelId,
    required this.stay,
    required this.party,
  });

  final String hotelId;
  final StayRange stay;
  final GuestParty party;

  @override
  bool operator ==(Object other) =>
      other is AvailabilityRequest &&
      other.hotelId == hotelId &&
      other.stay == stay &&
      other.party == party;

  @override
  int get hashCode => Object.hash(hotelId, stay, party);

  @override
  String toString() =>
      'AvailabilityRequest($hotelId, $stay, adults ${party.adults}, children ${party.children})';
}
