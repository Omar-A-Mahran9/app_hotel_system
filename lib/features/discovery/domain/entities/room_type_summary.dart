import 'package:flutter/foundation.dart';

import 'hotel_facility.dart';
import 'localized_text.dart';
import 'money.dart';

typedef RoomTypeSpec = ({String label, String value});

/// A room-level amenity shown as an icon/label on the available-room card
/// (`16 · Stay dates & available rooms`). Only the values the design shows.
enum RoomAmenity { freeWifi, airConditioning, cityView, balcony, kitchenette }

/// The compact view of a room type in the available-rooms list.
///
/// [maxOccupancy], [breakfastIncluded] and [refundable] are attributes the
/// design's room chips display ("2 أشخاص", "إفطار مجاني", "إلغاء مجاني"); they
/// are not booking rules the mobile app enforces.
@immutable
class RoomTypeSummary {
  const RoomTypeSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.bedType,
    required this.maxOccupancy,
    required this.amenities,
    required this.nightlyRate,
    required this.breakfastIncluded,
    required this.refundable,
    this.areaSqm,
    this.view,
    this.customSpecs = const <RoomTypeSpec>[],
    this.galleryUrls = const <String>[],
    this.tag,
    this.inclusions = const <LocalizedText>[],
    this.facilities = const <HotelFacility>[],
  });

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final LocalizedText bedType;
  final int maxOccupancy;
  final List<RoomAmenity> amenities;
  final Money nightlyRate;
  final bool breakfastIncluded;
  final bool refundable;

  /// Room floor area in square metres, shown as a spec chip on the room / hotel
  /// detail screens (`32 م²`). `null` when the source does not provide it.
  final int? areaSqm;

  /// The room type's view ("إطلالة المدينة"), shown as a spec chip. `null`
  /// when the source has none on file.
  final LocalizedText? view;

  /// Hotel-defined room specifications displayed alongside the built-in facts.
  final List<RoomTypeSpec> customSpecs;

  /// Real gallery photo URLs (`gallery[].url` on the backend room-type /
  /// availability resource), in display order. Empty when the room type has
  /// no media on file — never padded with stock photos.
  final List<String> galleryUrls;

  /// The first gallery photo — the cover shown on the available-rooms list
  /// card (`16 · Stay dates & available rooms`). `null` when there is no
  /// photo on file, which renders the branded placeholder instead.
  /// Optional operator badge on the room detail ("غرفة مميزة"); `null` = none.
  final LocalizedText? tag;

  /// Operator-managed "the rate includes" items (besides breakfast / free
  /// cancellation, which come from their own flags).
  final List<LocalizedText> inclusions;

  /// The room's facilities from the admin-managed catalog (label + icon),
  /// in the order the operator assigned them.
  final List<HotelFacility> facilities;

  String? get coverUrl => galleryUrls.isEmpty ? null : galleryUrls.first;

  @override
  bool operator ==(Object other) =>
      other is RoomTypeSummary &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.bedType == bedType &&
      other.maxOccupancy == maxOccupancy &&
      listEquals(other.amenities, amenities) &&
      other.nightlyRate == nightlyRate &&
      other.breakfastIncluded == breakfastIncluded &&
      other.refundable == refundable &&
      other.areaSqm == areaSqm &&
      other.view == view &&
      listEquals(other.customSpecs, customSpecs) &&
      listEquals(other.galleryUrls, galleryUrls) &&
      other.tag == tag &&
      listEquals(other.inclusions, inclusions) &&
      listEquals(other.facilities, facilities);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    bedType,
    maxOccupancy,
    Object.hashAll(amenities),
    nightlyRate,
    breakfastIncluded,
    refundable,
    areaSqm,
    view,
    Object.hashAll(customSpecs),
    Object.hashAll(galleryUrls),
    tag,
    Object.hashAll(inclusions),
    Object.hashAll(facilities),
  );
}
