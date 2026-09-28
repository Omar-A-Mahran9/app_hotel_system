import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/hotel_filters.dart';
import '../../domain/entities/hotel_search_result.dart';
import '../../domain/entities/hotel_summary.dart';
import 'discovery_providers.dart';

/// The nightly-rate spread across the whole catalogue, used to bound the price
/// slider in the filter sheet. Derived from the data, not an invented range.
final priceBoundsProvider = FutureProvider<PriceRange>((Ref ref) async {
  final HotelSearchResult all =
      await ref.watch(discoveryRepositoryProvider).searchHotels();
  if (all.hotels.isEmpty) return const PriceRange(min: 0, max: 0);

  // Whole-currency slider bounds that still contain every fractional rate.
  final Iterable<num> rates =
      all.hotels.map((HotelSummary h) => h.nightlyRateFrom.amount);
  return PriceRange(
    min: rates.reduce((num a, num b) => a < b ? a : b).floor(),
    max: rates.reduce((num a, num b) => a > b ? a : b).ceil(),
  );
});
