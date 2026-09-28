import 'package:flutter/foundation.dart';

import 'hotel_summary.dart';

/// The outcome of a hotel search: the matching summaries plus the total the data
/// source counted (drives "١٢ فندقاً متاحاً"). [hotels] is already filtered and
/// sorted by the data source — the presentation layer does not re-order it.
@immutable
class HotelSearchResult {
  const HotelSearchResult({required this.hotels, required this.totalCount});

  final List<HotelSummary> hotels;
  final int totalCount;

  bool get isEmpty => hotels.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is HotelSearchResult &&
      listEquals(other.hotels, hotels) &&
      other.totalCount == totalCount;

  @override
  int get hashCode => Object.hash(Object.hashAll(hotels), totalCount);
}
