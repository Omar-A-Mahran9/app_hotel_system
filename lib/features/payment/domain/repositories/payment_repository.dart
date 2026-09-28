import '../entities/payment.dart';
import '../entities/payment_request.dart';
import '../entities/payment_result.dart';

/// The payment contract the presentation layer depends on
/// (mobile/docs/architecture.md §4). Which data source fulfils it (dummy vs the
/// future guest payment API) is a DI decision, exactly as in
/// `ReservationRepository` / `DiscoveryRepository`.
///
/// Every method throws a `Failure` on error (mapped by the implementation) so
/// callers only handle the user-safe type. No method exposes provider,
/// transaction or credential detail.
abstract interface class PaymentRepository {
  /// The current payment for a reservation. Returns a synthetic
  /// [Payment.none] (status `NOT_STARTED`) when no payment record exists yet,
  /// so the review screen always has an authoritative amount to show.
  Future<Payment> currentForReservation(String reservationId);

  /// Requests a deposit hold. The backend resolves the `Payment` status; this
  /// never manufactures success locally.
  Future<PaymentResult> requestHold(PaymentHoldRequest request);
}
