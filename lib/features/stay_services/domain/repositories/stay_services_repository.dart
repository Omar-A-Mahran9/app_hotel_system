import '../entities/hotel_service.dart';
import '../entities/service_order.dart';

/// The stay-services contract the presentation layer depends on
/// (mobile/docs/architecture.md §4). Dummy vs API is a DI decision, exactly as in
/// `PaymentRepository`.
///
/// Every method throws a `Failure` on error (mapped by the implementation).
/// The app **displays** backend values only — it never computes folio amounts,
/// marks an order confirmed/fulfilled, or mutates accounting.
abstract interface class StayServicesRepository {
  /// The hotel's service catalogue (categories + services).
  Future<ServiceCatalogue> catalogue(String hotelId);

  /// The guest's service orders for a reservation, newest first.
  Future<List<ServiceOrder>> ordersFor(String reservationId);

  /// A single order by id.
  Future<ServiceOrder> orderById(String reservationId, String orderId);

  /// Requests a service. The backend creates the order in `requested`; nothing
  /// here transitions it or posts a folio charge.
  Future<ServiceOrder> requestService(CreateServiceRequest request);

  /// Cancels a still-`requested` order (`requested → cancelled`). The backend
  /// remains the authority on whether cancellation is allowed.
  Future<ServiceOrder> cancelOrder(String reservationId, String orderId);
}
