import '../../../../core/errors/error_mapper.dart';
import '../../../discovery/domain/entities/localized_text.dart';
import '../../domain/entities/hotel_service.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/repositories/stay_services_repository.dart';
import '../datasources/stay_services_data_source.dart';
import '../models/stay_services_models.dart';

/// Coordinates the stay-services data source, maps DTO models to domain
/// entities, and joins each order with the catalogue to attach a display name.
/// Dummy vs API is a DI decision. Every data-layer error is mapped to a
/// `Failure` via [ErrorMapper].
class StayServicesRepositoryImpl implements StayServicesRepository {
  StayServicesRepositoryImpl(this._dataSource);

  final StayServicesDataSource _dataSource;

  /// Filled by the first [catalogue] call and reused to attach display names to
  /// orders. In dummy mode the catalogue is hotel-agnostic; once the guest API
  /// is wired the reservation's hotel id must be threaded through here.
  ServiceCatalogue? _cachedCatalogue;

  @override
  Future<ServiceCatalogue> catalogue(String hotelId) => _guard(() async {
        final ServiceCatalogue c = await _dataSource.fetchCatalogue(hotelId);
        _cachedCatalogue = c;
        return c;
      });

  @override
  Future<List<ServiceOrder>> ordersFor(String reservationId) => _guard(() async {
        final List<ServiceOrderModel> models =
            await _dataSource.fetchOrders(reservationId);
        final ServiceCatalogue cat = await _catalogue();
        return models
            .map((ServiceOrderModel m) =>
                m.toEntity(serviceName: _nameFor(cat, m.serviceId)))
            .toList(growable: false);
      });

  @override
  Future<ServiceOrder> orderById(String reservationId, String orderId) =>
      _guard(() async {
        final ServiceOrderModel m =
            await _dataSource.fetchOrder(reservationId, orderId);
        final ServiceCatalogue cat = await _catalogue();
        return m.toEntity(serviceName: _nameFor(cat, m.serviceId));
      });

  @override
  Future<ServiceOrder> requestService(CreateServiceRequest request) =>
      _guard(() async {
        final ServiceOrderModel m = await _dataSource.createOrder(request);
        // The request already carries an authoritative display name snapshot.
        return m.toEntity(serviceName: request.serviceName);
      });

  @override
  Future<ServiceOrder> cancelOrder(String reservationId, String orderId) =>
      _guard(() async {
        final ServiceOrderModel m =
            await _dataSource.cancelOrder(reservationId, orderId);
        final ServiceCatalogue cat = await _catalogue();
        return m.toEntity(serviceName: _nameFor(cat, m.serviceId));
      });

  Future<ServiceCatalogue> _catalogue() async =>
      _cachedCatalogue ??= await _dataSource.fetchCatalogue('');

  LocalizedText _nameFor(ServiceCatalogue cat, String serviceId) {
    final HotelService? s = cat.serviceById(serviceId);
    return s?.name ?? LocalizedText(ar: '#$serviceId', en: '#$serviceId');
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
