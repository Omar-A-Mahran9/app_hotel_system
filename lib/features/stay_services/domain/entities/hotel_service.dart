import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/localized_text.dart';
import '../../../discovery/domain/entities/money.dart';

/// A hotel-scoped grouping for the service catalogue, mirroring the safe fields
/// of the Laravel `ServiceCategoryResource` (`id`, `name`, `description`,
/// `is_active`). `name` / `description` are plain strings on the wire; the app
/// wraps them as [LocalizedText] (the dummy catalogue supplies both languages,
/// a real API would be locale-negotiated server-side, matching the discovery
/// feature).
@immutable
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.isActive,
    this.description,
  });

  final String id;
  final LocalizedText name;
  final LocalizedText? description;
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      other is ServiceCategory &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, name, description, isActive);
}

/// Something a guest can request during a stay, mirroring the safe fields of
/// the Laravel `ServiceResource` (`id`, `service_category_id`, `name`,
/// `description`, `price`, `currency`, `is_active`). Simple pricing only — a
/// single [price], no taxes/discounts/tiers (backend R54).
///
/// [estimatedMinutes] is **not** part of the approved `ServiceResource` — it
/// backs the "~20 min" chip in `11 · Services & requests`. The dummy catalogue
/// supplies it; the (stubbed) API leaves it `null` (documented gap).
@immutable
class HotelService {
  const HotelService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isActive,
    this.categoryId,
    this.estimatedMinutes,
    this.rating,
    this.reviewsCount = 0,
  });

  final String id;
  final String? categoryId;
  final LocalizedText name;
  final LocalizedText description;
  final Money price;
  final bool isActive;
  final int? estimatedMinutes;

  /// Real, per-service average from the service's own *published* reviews
  /// only — independent of the hotel's own rating (see backend
  /// `ServiceReview` domain). `null` when the service has none yet; never a
  /// fabricated default rating.
  final double? rating;

  /// Count of published reviews backing [rating] — genuinely `0`, not
  /// omitted, when there are none yet (drives a "no reviews yet" label
  /// rather than hiding the row).
  final int reviewsCount;

  /// The guest can only order a service that the hotel currently offers.
  bool get isOrderable => isActive;

  @override
  bool operator ==(Object other) =>
      other is HotelService &&
      other.id == id &&
      other.categoryId == categoryId &&
      other.name == name &&
      other.description == description &&
      other.price == price &&
      other.isActive == isActive &&
      other.estimatedMinutes == estimatedMinutes &&
      other.rating == rating &&
      other.reviewsCount == reviewsCount;

  @override
  int get hashCode => Object.hash(
        id,
        categoryId,
        name,
        description,
        price,
        isActive,
        estimatedMinutes,
        rating,
        reviewsCount,
      );
}

/// The hotel's service catalogue: its categories and its services. Grouping is
/// derived on the client, exactly as `11 · Services & requests` shows it.
@immutable
class ServiceCatalogue {
  const ServiceCatalogue({required this.categories, required this.services});

  static const ServiceCatalogue empty =
      ServiceCatalogue(categories: <ServiceCategory>[], services: <HotelService>[]);

  final List<ServiceCategory> categories;
  final List<HotelService> services;

  bool get isEmpty => services.isEmpty;

  /// Services grouped by their category (in catalogue order), with an
  /// `null`-category bucket last for uncategorised services. Only active
  /// services are listed; inactive ones are dropped rather than shown disabled
  /// (the design's lock glyph is for services that exist but can't be ordered
  /// right now — modelled here as simply absent from an authoritative list).
  List<(ServiceCategory?, List<HotelService>)> grouped() {
    final List<(ServiceCategory?, List<HotelService>)> out =
        <(ServiceCategory?, List<HotelService>)>[];
    for (final ServiceCategory category in categories) {
      final List<HotelService> inCategory = services
          .where((HotelService s) => s.categoryId == category.id && s.isActive)
          .toList(growable: false);
      if (inCategory.isNotEmpty) out.add((category, inCategory));
    }
    final List<HotelService> uncategorised = services
        .where((HotelService s) =>
            s.isActive &&
            (s.categoryId == null ||
                !categories.any((ServiceCategory c) => c.id == s.categoryId)))
        .toList(growable: false);
    if (uncategorised.isNotEmpty) out.add((null, uncategorised));
    return out;
  }

  HotelService? serviceById(String id) {
    for (final HotelService s in services) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ServiceCatalogue &&
      listEquals(other.categories, categories) &&
      listEquals(other.services, services);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(categories), Object.hashAll(services));
}
