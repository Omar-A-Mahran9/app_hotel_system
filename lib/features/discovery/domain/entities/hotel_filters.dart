import 'package:flutter/foundation.dart';

import 'hotel.dart';

/// An inclusive nightly-rate window. The bounds shown in the filter sheet come
/// from the spread of the dataset (min/max nightly rate), not an invented range.
@immutable
class PriceRange {
  const PriceRange({required this.min, required this.max});

  final int min;
  final int max;

  bool contains(int amount) => amount >= min && amount <= max;

  @override
  bool operator ==(Object other) =>
      other is PriceRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'PriceRange($min–$max)';
}

/// Typed, composable filter state for hotel search (`15 · Search, filters &
/// sort`, screen "تصفية النتائج"). Destination city, price range and
/// facilities are real, backend-applied filters. Rating ("التقييم") is shown
/// locked with a lock icon in the reference — no approved threshold rule
/// exists — and room-type has no stable cross-hotel taxonomy backing it; both
/// stay unavailable rather than invented.
@immutable
class HotelFilters {
  const HotelFilters({
    this.cityIds = const <String>{},
    this.priceRange,
    this.facilities = const <HotelAmenity>{},
  });

  /// Empty means "all cities".
  final Set<String> cityIds;

  /// `null` means "any price".
  final PriceRange? priceRange;

  /// Facilities a matching hotel must have — AND semantics, server-applied
  /// (`GET /guest/hotels?facilities=free_wifi,pool`). Empty means "any".
  final Set<HotelAmenity> facilities;

  static const HotelFilters none = HotelFilters();

  bool get isActive =>
      cityIds.isNotEmpty || priceRange != null || facilities.isNotEmpty;

  int get activeCount =>
      (cityIds.isNotEmpty ? 1 : 0) +
      (priceRange != null ? 1 : 0) +
      (facilities.isNotEmpty ? 1 : 0);

  HotelFilters copyWith({
    Set<String>? cityIds,
    PriceRange? priceRange,
    Set<HotelAmenity>? facilities,
    bool clearPriceRange = false,
  }) {
    return HotelFilters(
      cityIds: cityIds ?? this.cityIds,
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      facilities: facilities ?? this.facilities,
    );
  }

  HotelFilters toggleCity(String cityId) {
    final Set<String> next = Set<String>.of(cityIds);
    if (!next.remove(cityId)) next.add(cityId);
    return copyWith(cityIds: next);
  }

  HotelFilters toggleFacility(HotelAmenity facility) {
    final Set<HotelAmenity> next = Set<HotelAmenity>.of(facilities);
    if (!next.remove(facility)) next.add(facility);
    return copyWith(facilities: next);
  }

  @override
  bool operator ==(Object other) =>
      other is HotelFilters &&
      setEquals(other.cityIds, cityIds) &&
      other.priceRange == priceRange &&
      setEquals(other.facilities, facilities);

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(cityIds),
        priceRange,
        Object.hashAllUnordered(facilities),
      );
}
