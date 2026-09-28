// Data-transfer models for the stay-services feature.
//
// Models mirror the safe Laravel resources: `ServiceCategoryResource`,
// `ServiceResource`, `ServiceOrderResource`. `ServiceOrderCreatePayload.toJson`
// mirrors `StoreServiceOrderRequest` (`service_id`, `quantity`, `notes?`).
// Money on the wire is a `decimal:2` string; the app's [Money] is whole units.

import '../../../discovery/domain/entities/localized_text.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../domain/entities/hotel_service.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/entities/service_order_status.dart';

typedef Json = Map<String, Object?>;

num _money(Object? raw) => Money.parseAmount(raw);

DateTime? _dateOrNull(Object? raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}

/// Wraps a plain wire string as [LocalizedText] (same value both languages) —
/// the fallback the discovery feature uses until the backend serialises
/// localised catalogue text.
LocalizedText _text(Object? raw) {
  final String v = raw is String ? raw : '';
  return LocalizedText(ar: v, en: v);
}

class ServiceCategoryModel {
  const ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.description,
  });

  factory ServiceCategoryModel.fromJson(Json json) => ServiceCategoryModel(
        id: '${json['id']}',
        name: _text(json['name']),
        description:
            json['description'] == null ? null : _text(json['description']),
        isActive: json['is_active'] as bool? ?? true,
      );

  final String id;
  final LocalizedText name;
  final LocalizedText? description;
  final bool isActive;

  ServiceCategory toEntity() => ServiceCategory(
        id: id,
        name: name,
        description: description,
        isActive: isActive,
      );
}

class HotelServiceModel {
  const HotelServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.isActive,
    this.categoryId,
    this.estimatedMinutes,
    this.rating,
    this.reviewsCount = 0,
  });

  factory HotelServiceModel.fromJson(Json json) => HotelServiceModel(
        id: '${json['id']}',
        categoryId: json['service_category_id'] == null
            ? null
            : '${json['service_category_id']}',
        name: _text(json['name']),
        description: _text(json['description']),
        price: _money(json['price']),
        currency: (json['currency'] as String?) ?? Money.fallbackCurrency,
        isActive: json['is_active'] as bool? ?? true,
        estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt(),
        // Real, per-service aggregate from published service reviews only
        // (`ServiceResource.rating`/`reviews_count`) — `rating` absent/null
        // means unreviewed, never a fabricated default.
        rating: _rating(json['rating']),
        reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String? categoryId;
  final LocalizedText name;
  final LocalizedText description;
  final num price;
  final String currency;
  final bool isActive;
  final int? estimatedMinutes;
  final double? rating;
  final int reviewsCount;

  HotelService toEntity() => HotelService(
        id: id,
        categoryId: categoryId,
        name: name,
        description: description,
        price: Money(amount: price, currency: currency),
        isActive: isActive,
        estimatedMinutes: estimatedMinutes,
        rating: rating,
        reviewsCount: reviewsCount,
      );

  static double? _rating(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }
}

/// The request body for `POST .../service-orders`.
class ServiceOrderCreatePayload {
  const ServiceOrderCreatePayload({
    required this.serviceId,
    required this.quantity,
    this.notes,
  });

  factory ServiceOrderCreatePayload.fromRequest(CreateServiceRequest r) =>
      ServiceOrderCreatePayload(
        serviceId: r.serviceId,
        quantity: r.quantity,
        notes: r.notes,
      );

  final String serviceId;
  final int quantity;
  final String? notes;

  Json toJson() => <String, Object?>{
        'service_id': int.tryParse(serviceId) ?? serviceId,
        'quantity': quantity,
        if (notes != null) 'notes': notes,
      };
}

class ServiceOrderModel {
  const ServiceOrderModel({
    required this.id,
    required this.reservationId,
    required this.serviceId,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    required this.totalAmount,
    required this.status,
    required this.requestedAt,
    this.notes,
    this.confirmedAt,
    this.fulfilledAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory ServiceOrderModel.fromJson(Json json) => ServiceOrderModel(
        id: '${json['id']}',
        reservationId: '${json['reservation_id']}',
        serviceId: '${json['service_id']}',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: _money(json['unit_price_snapshot']),
        currency: (json['currency_snapshot'] as String?) ?? Money.fallbackCurrency,
        totalAmount: _money(json['total_amount']),
        status: ServiceOrderStatus.fromWire(
          (json['status'] as String?) ?? ServiceOrderStatus.requested.wireValue,
        ),
        notes: json['notes'] as String?,
        requestedAt: _dateOrNull(json['requested_at']) ??
            _dateOrNull(json['created_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        confirmedAt: _dateOrNull(json['confirmed_at']),
        fulfilledAt: _dateOrNull(json['fulfilled_at']),
        cancelledAt: _dateOrNull(json['cancelled_at']),
        cancellationReason: json['cancellation_reason'] as String?,
      );

  final String id;
  final String reservationId;
  final String serviceId;
  final int quantity;
  final num unitPrice;
  final String currency;
  final num totalAmount;
  final ServiceOrderStatus status;
  final String? notes;
  final DateTime requestedAt;
  final DateTime? confirmedAt;
  final DateTime? fulfilledAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  ServiceOrder toEntity({required LocalizedText serviceName}) => ServiceOrder(
        id: id,
        reservationId: reservationId,
        serviceId: serviceId,
        serviceName: serviceName,
        quantity: quantity,
        unitPrice: Money(amount: unitPrice, currency: currency),
        totalAmount: Money(amount: totalAmount, currency: currency),
        status: status,
        notes: notes,
        requestedAt: requestedAt,
        confirmedAt: confirmedAt,
        fulfilledAt: fulfilledAt,
        cancelledAt: cancelledAt,
        cancellationReason: cancellationReason,
      );
}
