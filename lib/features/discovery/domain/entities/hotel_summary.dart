import 'package:flutter/foundation.dart';

import 'localized_text.dart';
import 'money.dart';

/// The compact view of a hotel shown in discover cards and search-result rows
/// (`02 · Discover & Book`). The full [Hotel] adds the detail-screen fields.
@immutable
class HotelSummary {
  const HotelSummary({
    required this.id,
    required this.name,
    required this.cityId,
    required this.cityName,
    required this.tagline,
    required this.rating,
    required this.reviewCount,
    required this.nightlyRateFrom,
    required this.isAvailable,
    this.coverUrl,
    this.starRating,
  });

  final String id;
  final LocalizedText name;
  final String cityId;
  final LocalizedText cityName;
  final LocalizedText tagline;

  /// Average guest rating out of 5 (`4.96` in the reference). `null` when the
  /// hotel has no ratings yet — the card then hides the rating pill.
  final double? rating;
  final int? reviewCount;

  /// The hotel's own 1-5 star classification (`star_rating` on the backend
  /// hotel resource) — a different concept from [rating] (the average guest
  /// review score) and never substituted for it. `null` when the hotel has
  /// none on file.
  final int? starRating;

  /// Lowest nightly rate across the hotel's room types — the "from" price on the
  /// card.
  final Money nightlyRateFrom;

  final bool isAvailable;

  /// The backend's real `cover_url` for this hotel, or `null` when none is on
  /// file — the card then shows the branded placeholder, never a stock photo.
  final String? coverUrl;

  @override
  bool operator ==(Object other) =>
      other is HotelSummary &&
      other.id == id &&
      other.name == name &&
      other.cityId == cityId &&
      other.cityName == cityName &&
      other.tagline == tagline &&
      other.rating == rating &&
      other.reviewCount == reviewCount &&
      other.nightlyRateFrom == nightlyRateFrom &&
      other.isAvailable == isAvailable &&
      other.coverUrl == coverUrl &&
      other.starRating == starRating;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        cityId,
        cityName,
        tagline,
        rating,
        reviewCount,
        nightlyRateFrom,
        isAvailable,
        coverUrl,
        starRating,
      );
}
