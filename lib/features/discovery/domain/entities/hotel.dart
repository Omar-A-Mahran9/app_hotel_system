import 'package:flutter/foundation.dart';

import 'hotel_facility.dart';
import 'hotel_guest_details.dart';
import 'hotel_review_summary.dart';
import 'hotel_summary.dart';
import 'localized_text.dart';
import 'room_type_summary.dart';

/// A search-*filter* facility vocabulary (`15 · Search, filters & sort`) —
/// deliberately separate from [HotelFacility], which is what a *specific*
/// hotel actually has on file (an open, admin-managed catalog). This stays a
/// small fixed set because the filter sheet's chips are a client-side
/// enumeration, not a rendering of backend data.
enum HotelAmenity {
  freeWifi,
  breakfast,
  parking,
  pool,
  gym,
  familyRooms,
  airportShuttle,
  roomService,
}

/// The full hotel, backing the detail screen. Composes [summary] so lists and
/// the detail screen share exactly one source of the shared fields.
@immutable
class Hotel {
  const Hotel({
    required this.summary,
    required this.description,
    required this.facilities,
    required this.roomTypeCount,
    required this.photoCount,
    this.entryRoom,
    this.galleryUrls = const <String>[],
    this.country,
    this.reviewSummary,
    this.details = const HotelGuestDetails(),
  });

  final HotelSummary summary;
  final LocalizedText description;

  /// This hotel's real facility catalog membership (`amenities` on the
  /// backend hotel resource) — an open, admin-managed list, never the fixed
  /// [HotelAmenity] filter vocabulary. Empty when the hotel has none on file.
  final List<HotelFacility> facilities;

  /// Number of room types the hotel offers — the detail screen shows it and the
  /// photo strip uses [photoCount] for its "+N" overflow tile.
  final int roomTypeCount;
  final int photoCount;

  /// The hotel's entry-level (cheapest bookable) room type — the detail screen
  /// shows its area / occupancy / bed as spec chips. `null` when the source has
  /// no room offerings.
  final RoomTypeSummary? entryRoom;

  /// Real gallery photo URLs (`gallery[].url` on the backend hotel resource),
  /// in display order — backs the hero photo strip. Empty when the hotel has
  /// no gallery media on file; never padded with stock photos.
  final List<String> galleryUrls;

  /// The hotel's country (`country` on the backend hotel resource), shown on
  /// the detail screen's info row. `null` when the source has none on file —
  /// the row then just omits the chip, never a guessed/hardcoded country.
  final LocalizedText? country;

  /// Live guest-rating summary with the hotel's **dynamic** review
  /// categories (`review_summary` on the detail endpoint). `null` when the
  /// source has none (dummy mode) — never fabricated.
  final HotelReviewSummary? reviewSummary;

  /// Operator-managed detail content (check-in/out, suitable for, rooms,
  /// highlights, location) — `details` on the detail endpoint. Empty when the
  /// source has none on file (dummy mode); never fabricated.
  final HotelGuestDetails details;

  String get id => summary.id;
  LocalizedText get name => summary.name;
  String? get coverUrl => summary.coverUrl;

  @override
  bool operator ==(Object other) =>
      other is Hotel &&
      other.summary == summary &&
      other.description == description &&
      listEquals(other.facilities, facilities) &&
      other.roomTypeCount == roomTypeCount &&
      other.photoCount == photoCount &&
      other.entryRoom == entryRoom &&
      listEquals(other.galleryUrls, galleryUrls) &&
      other.country == country &&
      other.reviewSummary == reviewSummary &&
      other.details == details;

  @override
  int get hashCode => Object.hash(
        summary,
        description,
        Object.hashAll(facilities),
        roomTypeCount,
        photoCount,
        entryRoom,
        Object.hashAll(galleryUrls),
        country,
        reviewSummary,
        details,
      );
}
