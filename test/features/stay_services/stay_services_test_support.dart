import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/stay_services/data/datasources/dummy_stay_services_data_source.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order.dart';

export '../payment/payment_test_support.dart' show fakeReservation;

const LocalizedText kRoomCleaning =
    LocalizedText(ar: 'تنظيف الغرفة', en: 'Room cleaning');

CreateServiceRequest fakeServiceRequest({
  String reservationId = 'res-1',
  String serviceId = '101',
  int quantity = 1,
  String? notes,
}) =>
    CreateServiceRequest(
      reservationId: reservationId,
      serviceId: serviceId,
      serviceName: kRoomCleaning,
      quantity: quantity,
      notes: notes,
    );

/// The first order id (`o0`, `o1`, …) mapping to [progress].
String orderIdForProgress(DummyOrderProgress progress) {
  for (int i = 0; i < 800; i++) {
    final String id = 'o$i';
    if (DummyStayServicesDataSource.progressFor(id) == progress) return id;
  }
  throw StateError('no id found for $progress');
}

/// The first reservation id whose *first created order* stays `requested`
/// (i.e. the order id the dummy derives from that reservation's request key is
/// a "staysRequested" bucket), so cancellation is exercisable.
String reservationIdWithCancellableOrder() {
  for (int i = 0; i < 800; i++) {
    final String rid = 'sr$i';
    final String key = fakeServiceRequest(reservationId: rid).idempotencyKey;
    final int hash = _fnv1a(key);
    final String orderId = '${2200 + (hash % 7000)}';
    if (DummyStayServicesDataSource.progressFor(orderId) ==
        DummyOrderProgress.staysRequested) {
      return rid;
    }
  }
  throw StateError('no reservation with a cancellable first order');
}

/// The first reservation id whose first created order is already `confirmed`
/// (so a guest cancel is rejected).
String reservationIdWithConfirmedOrder() {
  for (int i = 0; i < 800; i++) {
    final String rid = 'sc$i';
    final String key = fakeServiceRequest(reservationId: rid).idempotencyKey;
    final int hash = _fnv1a(key);
    final String orderId = '${2200 + (hash % 7000)}';
    if (DummyStayServicesDataSource.progressFor(orderId) !=
        DummyOrderProgress.staysRequested) {
      return rid;
    }
  }
  throw StateError('no reservation with a confirmed first order');
}

int _fnv1a(String value) {
  int hash = 0x811c9dc5;
  for (final int unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}
