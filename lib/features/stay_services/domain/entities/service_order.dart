import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/localized_text.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../../reservation/domain/entities/reservation.dart';
import 'service_order_status.dart';

/// A service the guest requested for their stay, mirroring the safe fields of
/// the Laravel `ServiceOrderResource` (`id`, `reservation_id`, `service_id`,
/// `quantity`, `unit_price_snapshot`, `currency_snapshot`, `total_amount`,
/// `status`, `notes`, timestamps, `cancellation_reason`).
///
/// ACCOUNTING: [totalAmount] is the **authoritative** figure from the backend
/// snapshot — the app never recomputes `unitPrice × quantity` from a real
/// response, never marks an order confirmed/fulfilled, and never touches the
/// folio (phase brief §"Phase 8 accounting rule").
///
/// [serviceName] is a display snapshot carried from the request / catalogue so
/// the list renders without another lookup (mirrors `Reservation.hotelName`).
@immutable
class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.reservationId,
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.status,
    required this.requestedAt,
    this.notes,
    this.confirmedAt,
    this.fulfilledAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  final String id;
  final String reservationId;
  final String serviceId;
  final LocalizedText serviceName;
  final int quantity;
  final Money unitPrice;
  final Money totalAmount;
  final ServiceOrderStatus status;
  final String? notes;
  final DateTime requestedAt;
  final DateTime? confirmedAt;
  final DateTime? fulfilledAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  /// A short human reference for the "request received" screen (`SR-2291`).
  String get reference => 'SR-$id';

  bool get isGuestCancellable => status.isGuestCancellable;

  @override
  bool operator ==(Object other) =>
      other is ServiceOrder &&
      other.id == id &&
      other.reservationId == reservationId &&
      other.serviceId == serviceId &&
      other.serviceName == serviceName &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice &&
      other.totalAmount == totalAmount &&
      other.status == status &&
      other.notes == notes &&
      other.requestedAt == requestedAt &&
      other.confirmedAt == confirmedAt &&
      other.fulfilledAt == fulfilledAt &&
      other.cancelledAt == cancelledAt &&
      other.cancellationReason == cancellationReason;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        reservationId,
        serviceId,
        serviceName,
        quantity,
        unitPrice,
        totalAmount,
        status,
        notes,
        requestedAt,
        confirmedAt,
        fulfilledAt,
        cancelledAt,
        cancellationReason,
      ]);

  @override
  String toString() => 'ServiceOrder($reference, ${status.wireValue})';
}

/// Everything the mobile app can supply to request a service.
///
/// The approved backend `POST /api/v1/reservations/{reservation}/service-orders`
/// (`StoreServiceOrderRequest`) takes `service_id`, `quantity`, optional
/// `notes` and derives everything else. That endpoint is staff/dashboard-scoped
/// (`ReservationService::findAccessibleBy` + `ServiceOrderPolicy`), so this
/// request carries only those fields plus a display snapshot of the service
/// name and a stable idempotency key.
@immutable
class CreateServiceRequest {
  const CreateServiceRequest({
    required this.reservationId,
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    this.notes,
  });

  factory CreateServiceRequest.forReservation(
    Reservation reservation, {
    required String serviceId,
    required LocalizedText serviceName,
    int quantity = 1,
    String? notes,
  }) {
    return CreateServiceRequest(
      reservationId: reservation.id,
      serviceId: serviceId,
      serviceName: serviceName,
      quantity: quantity,
      notes: (notes != null && notes.trim().isEmpty) ? null : notes?.trim(),
    );
  }

  final String reservationId;
  final String serviceId;
  final LocalizedText serviceName;
  final int quantity;
  final String? notes;

  /// Stable idempotency key for this exact request. Quantity and notes are part
  /// of it so changing the order is a different operation; there is no time or
  /// random component.
  String get idempotencyKey => <String>[
        'svc',
        reservationId,
        serviceId,
        '$quantity',
        notes ?? '-',
      ].join('|');

  @override
  bool operator ==(Object other) =>
      other is CreateServiceRequest &&
      other.reservationId == reservationId &&
      other.serviceId == serviceId &&
      other.quantity == quantity &&
      other.notes == notes;

  @override
  int get hashCode =>
      Object.hash(reservationId, serviceId, quantity, notes);

  @override
  String toString() => 'CreateServiceRequest($idempotencyKey)';
}
