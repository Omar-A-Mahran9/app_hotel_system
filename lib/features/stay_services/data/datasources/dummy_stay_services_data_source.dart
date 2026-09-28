import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/hotel_service.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/entities/service_order_status.dart';
import '../fixtures/service_catalogue_fixture.dart';
import '../models/stay_services_models.dart';
import 'stay_services_data_source.dart';

/// A deterministic hotel-side status for a service order, chosen purely from
/// the order id.
enum DummyOrderProgress { staysRequested, getsConfirmed, getsFulfilled }

/// Deterministic, offline stay-services source used while no guest-facing
/// contract is approved.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness, no `DateTime.now()` branching (a
///   `clock` is injected for the request timestamp only);
/// * the catalogue is the fixed [ServiceCatalogueFixture] (same for every
///   hotel in dummy mode — documented);
/// * [createOrder] is idempotent per request (same [CreateServiceRequest]
///   returns the order already made);
/// * a created order is `requested`; the hotel-side status it later reports is
///   a pure function of the order id ([progressFor]);
/// * the app never computes the folio — `total_amount` here is a deterministic
///   `unit_price × quantity` **sample** only, in the same DTO shape the backend
///   would send.
///
/// [failWith] is a test seam.
class DummyStayServicesDataSource
    implements StayServicesDataSource, DummyDataSource {
  DummyStayServicesDataSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// reservationId -> (orderId -> record)
  final Map<String, Map<String, _OrderRecord>> _orders =
      <String, Map<String, _OrderRecord>>{};
  final Map<String, String> _idByKey = <String, String>{};

  Object? failWith;

  static DummyOrderProgress progressFor(String orderId) {
    switch (_fnv1a(orderId) % 3) {
      case 0:
        return DummyOrderProgress.staysRequested;
      case 1:
        return DummyOrderProgress.getsConfirmed;
      default:
        return DummyOrderProgress.getsFulfilled;
    }
  }

  @override
  Future<ServiceCatalogue> fetchCatalogue(String hotelId) async {
    if (failWith != null) throw failWith!;
    return ServiceCatalogueFixture.catalogue;
  }

  @override
  Future<List<ServiceOrderModel>> fetchOrders(String reservationId) async {
    if (failWith != null) throw failWith!;
    final Iterable<_OrderRecord> records =
        (_orders[reservationId] ?? const <String, _OrderRecord>{}).values;
    final List<ServiceOrderModel> out = records
        .map((_OrderRecord r) => _model(r))
        .toList(growable: true)
      ..sort((ServiceOrderModel a, ServiceOrderModel b) =>
          b.requestedAt.compareTo(a.requestedAt));
    return out;
  }

  @override
  Future<ServiceOrderModel> fetchOrder(
      String reservationId, String orderId) async {
    if (failWith != null) throw failWith!;
    final _OrderRecord? record = _orders[reservationId]?[orderId];
    if (record == null) {
      throw NotFoundException('No service order "$orderId"');
    }
    return _model(record);
  }

  @override
  Future<ServiceOrderModel> createOrder(CreateServiceRequest request) async {
    if (failWith != null) throw failWith!;

    final String? existingId = _idByKey[request.idempotencyKey];
    final _OrderRecord? existing =
        _orders[request.reservationId]?[existingId];
    if (existing != null) return _model(existing);

    final HotelService? service =
        ServiceCatalogueFixture.serviceById(request.serviceId);
    if (service == null) {
      throw NotFoundException('No service "${request.serviceId}"');
    }

    final int hash = _fnv1a(request.idempotencyKey);
    final String id = '${2200 + (hash % 7000)}';
    final num unit = service.price.amount;

    final _OrderRecord record = _OrderRecord(
      id: id,
      reservationId: request.reservationId,
      serviceId: request.serviceId,
      quantity: request.quantity,
      unitPrice: unit,
      currency: service.price.currency,
      // Deterministic sample total in the backend DTO shape — the app never
      // recomputes this from a real response.
      totalAmount: unit * request.quantity,
      notes: request.notes,
      requestedAt: _clock(),
      cancelled: false,
    );

    _orders.putIfAbsent(request.reservationId, () => <String, _OrderRecord>{})[id] =
        record;
    _idByKey[request.idempotencyKey] = id;
    return _model(record);
  }

  @override
  Future<ServiceOrderModel> cancelOrder(
      String reservationId, String orderId) async {
    if (failWith != null) throw failWith!;
    final _OrderRecord? record = _orders[reservationId]?[orderId];
    if (record == null) {
      throw NotFoundException('No service order "$orderId"');
    }
    if (!_resolvedStatus(record).isGuestCancellable) {
      // The hotel already actioned it — mirrors the backend rejecting an
      // invalid transition.
      throw const ConflictException('This request can no longer be cancelled');
    }
    record.cancelled = true;
    return _model(record);
  }

  ServiceOrderStatus _resolvedStatus(_OrderRecord r) {
    if (r.cancelled) return ServiceOrderStatus.cancelled;
    return switch (progressFor(r.id)) {
      DummyOrderProgress.staysRequested => ServiceOrderStatus.requested,
      DummyOrderProgress.getsConfirmed => ServiceOrderStatus.confirmed,
      DummyOrderProgress.getsFulfilled => ServiceOrderStatus.fulfilled,
    };
  }

  ServiceOrderModel _model(_OrderRecord r) {
    final ServiceOrderStatus status = _resolvedStatus(r);
    return ServiceOrderModel.fromJson(<String, Object?>{
      'id': r.id,
      'reservation_id': r.reservationId,
      'service_id': r.serviceId,
      'quantity': r.quantity,
      'unit_price_snapshot': r.unitPrice.toStringAsFixed(2),
      'currency_snapshot': r.currency,
      'total_amount': r.totalAmount.toStringAsFixed(2),
      'status': status.wireValue,
      'notes': r.notes,
      'requested_at': r.requestedAt.toIso8601String(),
      'confirmed_at': status == ServiceOrderStatus.confirmed ||
              status == ServiceOrderStatus.fulfilled
          ? r.requestedAt.toIso8601String()
          : null,
      'fulfilled_at': status == ServiceOrderStatus.fulfilled
          ? r.requestedAt.toIso8601String()
          : null,
      'cancelled_at':
          status == ServiceOrderStatus.cancelled
              ? r.requestedAt.toIso8601String()
              : null,
      'cancellation_reason':
          status == ServiceOrderStatus.cancelled ? 'guest_request' : null,
    });
  }

  static int _fnv1a(String value) {
    int hash = 0x811c9dc5;
    for (final int unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _OrderRecord {
  _OrderRecord({
    required this.id,
    required this.reservationId,
    required this.serviceId,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    required this.totalAmount,
    required this.notes,
    required this.requestedAt,
    required this.cancelled,
  });

  final String id;
  final String reservationId;
  final String serviceId;
  final int quantity;
  final num unitPrice;
  final String currency;
  final num totalAmount;
  final String? notes;
  final DateTime requestedAt;
  bool cancelled;
}
