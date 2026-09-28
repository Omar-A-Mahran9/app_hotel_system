import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/create_reservation_request.dart';
import '../../domain/entities/extend_stay.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../datasources/reservation_data_source.dart';

/// Coordinates the reservation data source and maps DTO models to domain
/// entities. Which [ReservationDataSource] it holds (dummy vs API) is a DI
/// decision, not made here (feature_guide.md Step 5). Every data-layer error is
/// mapped to a `Failure` via [ErrorMapper] so the presentation layer only
/// handles the user-safe type.
class ReservationRepositoryImpl implements ReservationRepository {
  ReservationRepositoryImpl(this._dataSource);

  final ReservationDataSource _dataSource;

  @override
  Future<Reservation> create(CreateReservationRequest request) =>
      _guard(() async => (await _dataSource.create(request)).toEntity());

  @override
  Future<Reservation> getById(String id) =>
      _guard(() async => (await _dataSource.fetchById(id)).toEntity());

  @override
  Future<List<Reservation>> list() => _guard(() async {
        final result = await _dataSource.fetchList();
        return result.map((m) => m.toEntity()).toList(growable: false);
      });

  @override
  Future<Reservation> cancel(String id) =>
      _guard(() async => (await _dataSource.cancel(id)).toEntity());

  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) =>
      _guard(() async => (await _dataSource.extend(request)).toEntity());

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
