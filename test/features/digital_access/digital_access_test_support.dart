import 'package:hotel_guest_app/features/digital_access/data/datasources/dummy_digital_access_data_source.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/check_in.dart';

export '../payment/payment_test_support.dart' show fakeReservation;

CheckInRequest fakeCheckInRequest({String reservationId = 'res-1'}) =>
    CheckInRequest(reservationId: reservationId);

/// The first reservation id (`c0`, `c1`, …) that maps to [scenario].
String reservationIdForCheckIn(DummyCheckInScenario scenario) {
  for (int i = 0; i < 500; i++) {
    final String id = 'c$i';
    if (DummyDigitalAccessDataSource.scenarioFor(id) == scenario) return id;
  }
  throw StateError('no id found for $scenario');
}
