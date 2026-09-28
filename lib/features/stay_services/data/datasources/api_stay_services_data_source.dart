import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/hotel_service.dart';
import '../../domain/entities/service_order.dart';
import '../models/stay_services_models.dart';
import 'stay_services_data_source.dart';

/// API-backed stay-services source.
///
/// Real, authenticated/public guest contract:
/// `GET /guest/hotels/{hotel}/service-categories` and `.../services` (public,
/// active-only, mirrors `GuestDiscoveryController`), and
/// `GET|POST /guest/reservations/{reservation}/service-orders`,
/// `GET .../service-orders/{serviceOrder}` and
/// `POST .../service-orders/{serviceOrder}/cancel` (`auth:guest`, reuses
/// `ServiceOrderService` — the state machine decides what is cancellable and
/// a refused cancel is a 422).
class ApiStayServicesDataSource
    implements StayServicesDataSource, RemoteDataSource {
  ApiStayServicesDataSource(this._client);

  final ApiClient _client;

  @override
  Future<ServiceCatalogue> fetchCatalogue(String hotelId) async {
    final Map<String, dynamic> categoriesJson = await _client.getJson(
      '/guest/hotels/$hotelId/service-categories',
    );
    final Map<String, dynamic> servicesJson = await _client.getJson(
      '/guest/hotels/$hotelId/services',
    );
    final List<Object?> categories =
        (categoriesJson['data'] as List<Object?>?) ?? const <Object?>[];
    final List<Object?> services =
        (servicesJson['data'] as List<Object?>?) ?? const <Object?>[];
    return ServiceCatalogue(
      categories: categories
          .whereType<Map<String, Object?>>()
          .map((Map<String, Object?> j) => ServiceCategoryModel.fromJson(j).toEntity())
          .toList(growable: false),
      services: services
          .whereType<Map<String, Object?>>()
          .map((Map<String, Object?> j) => HotelServiceModel.fromJson(j).toEntity())
          .toList(growable: false),
    );
  }

  @override
  Future<List<ServiceOrderModel>> fetchOrders(String reservationId) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/$reservationId/service-orders',
    );
    final List<Object?> data = (json['data'] as List<Object?>?) ?? const <Object?>[];
    return data
        .whereType<Map<String, Object?>>()
        .map(ServiceOrderModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ServiceOrderModel> fetchOrder(
    String reservationId,
    String orderId,
  ) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/$reservationId/service-orders/$orderId',
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return ServiceOrderModel.fromJson(data);
  }

  @override
  Future<ServiceOrderModel> createOrder(CreateServiceRequest request) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/reservations/${request.reservationId}/service-orders',
      body: ServiceOrderCreatePayload.fromRequest(request).toJson(),
      headers: <String, String>{'Idempotency-Key': request.idempotencyKey},
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return ServiceOrderModel.fromJson(data);
  }

  @override
  Future<ServiceOrderModel> cancelOrder(
    String reservationId,
    String orderId,
  ) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/reservations/$reservationId/service-orders/$orderId/cancel',
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return ServiceOrderModel.fromJson(data);
  }
}
