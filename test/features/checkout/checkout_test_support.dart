import 'package:hotel_guest_app/features/checkout/data/datasources/dummy_checkout_data_source.dart';
import 'package:hotel_guest_app/features/checkout/domain/repositories/checkout_repository.dart';

export '../payment/payment_test_support.dart' show fakeReservation;

FolioContext fakeFolioContext({
  String reservationId = 'res-1',
  int accommodationAmount = 900,
  String currency = 'SAR',
}) =>
    FolioContext(
      reservationId: reservationId,
      accommodationAmount: accommodationAmount,
      currency: currency,
    );

/// The first reservation id (`k0`, `k1`, …) that maps to [scenario].
String reservationIdForSettlement(DummySettlementScenario scenario) {
  for (int i = 0; i < 500; i++) {
    final String id = 'k$i';
    if (DummyCheckoutDataSource.scenarioFor(id) == scenario) return id;
  }
  throw StateError('no id found for $scenario');
}
