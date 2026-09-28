import '../entities/access_grant.dart';
import '../entities/check_in.dart';

/// The digital-access contract the presentation layer depends on
/// (mobile/docs/architecture.md §4). Dummy vs API is a DI decision, exactly as in
/// `PaymentRepository` / `ReservationRepository`.
///
/// Every method throws a `Failure` on error (mapped by the implementation) so
/// callers only handle the user-safe type. No method exposes provider,
/// credential-storage or access-control internals.
abstract interface class DigitalAccessRepository {
  /// The current access grant for a reservation. Returns
  /// [AccessGrant.notIssued] when check‑in has not run.
  Future<AccessGrant> currentGrant(String reservationId);

  /// Performs check‑in. The backend issues the access grant and drives
  /// `VERIFIED → CHECKED_IN`; nothing here transitions the reservation.
  Future<CheckInResult> checkIn(CheckInRequest request);
}
