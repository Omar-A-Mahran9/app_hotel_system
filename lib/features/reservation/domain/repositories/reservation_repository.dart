import '../entities/create_reservation_request.dart';
import '../entities/extend_stay.dart';
import '../entities/reservation.dart';

/// The reservation contract the presentation layer depends on
/// (mobile/docs/architecture.md §4). Which data source fulfils it (dummy vs
/// the future guest reservation API) is a DI decision, exactly as in
/// `DiscoveryRepository` / `AuthRepository`.
///
/// Every method throws a `Failure` on error (mapped by the implementation) so
/// callers only handle the user-safe type.
abstract interface class ReservationRepository {
  /// Creates a reservation. The backend places a new reservation in
  /// `PENDING`; nothing here transitions it further.
  Future<Reservation> create(CreateReservationRequest request);

  /// Fetches a previously created reservation by its id.
  Future<Reservation> getById(String id);

  /// The guest's own reservations, newest first — backs the Bookings tab.
  Future<List<Reservation>> list();

  /// Cancels a reservation the guest may still cancel. The backend enforces
  /// which statuses allow it; an out-of-window cancel surfaces as a `Failure`.
  Future<Reservation> cancel(String id);

  /// Requests a stay extension. The backend re-checks availability and prices
  /// the addition from the room type's nightly rate — this never invents a
  /// price or an outcome locally.
  Future<ExtendStayResult> extend(ExtendStayRequest request);
}
