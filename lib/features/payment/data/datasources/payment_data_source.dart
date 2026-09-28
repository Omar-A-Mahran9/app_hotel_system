import '../../domain/entities/payment_request.dart';
import '../models/payment_models.dart';

/// The payment data contract. Dummy + API implementations, selected by DI
/// (`AppConfig.useDummyData`) exactly like `ReservationDataSource`. Methods
/// return DTO models; the repository maps them to domain entities.
abstract interface class PaymentDataSource {
  /// The current payment for a reservation, or `null` when none exists yet.
  Future<PaymentModel?> fetchForReservation(String reservationId);

  /// Requests a deposit hold and returns the resolved payment.
  Future<PaymentModel> requestHold(PaymentHoldRequest request);
}
