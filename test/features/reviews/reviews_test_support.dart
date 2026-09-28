import 'package:hotel_guest_app/features/reviews/data/datasources/dummy_review_data_source.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review_draft.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

export '../payment/payment_test_support.dart' show fakeReservation;

ReviewContext fakeReviewContext({
  String reservationId = 'res-1',
  ReservationStatus status = ReservationStatus.checkedOut,
}) =>
    ReviewContext(reservationId: reservationId, reservationStatus: status);

/// The first reservation id (`RV0`, `RV1`, …) mapping to [scenario].
String reviewScenarioId(DummyReviewScenario scenario) {
  for (int i = 0; i < 4000; i++) {
    final String id = 'RV$i';
    if (DummyReviewDataSource.scenarioFor(id) == scenario) return id;
  }
  throw StateError('no reservation id found for $scenario');
}
