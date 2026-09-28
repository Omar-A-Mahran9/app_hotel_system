import '../../domain/entities/hotel_service.dart';
import '../../domain/entities/service_order.dart';
import '../models/stay_services_models.dart';

/// The stay-services data contract. Dummy + API implementations selected by DI.
///
/// The catalogue comes back as a domain [ServiceCatalogue] (its text is
/// bilingual and locale-negotiation is a server concern); orders come back as
/// DTO models the repository joins with the catalogue to attach a display name.
abstract interface class StayServicesDataSource {
  Future<ServiceCatalogue> fetchCatalogue(String hotelId);

  Future<List<ServiceOrderModel>> fetchOrders(String reservationId);

  Future<ServiceOrderModel> fetchOrder(String reservationId, String orderId);

  Future<ServiceOrderModel> createOrder(CreateServiceRequest request);

  Future<ServiceOrderModel> cancelOrder(String reservationId, String orderId);
}
