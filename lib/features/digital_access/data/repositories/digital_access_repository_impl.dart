import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/access_grant.dart';
import '../../domain/entities/check_in.dart';
import '../../domain/repositories/digital_access_repository.dart';
import '../datasources/digital_access_data_source.dart';

/// Coordinates the digital-access data source and maps DTO models to domain
/// entities. Dummy vs API is a DI decision. Every data-layer error is mapped to
/// a `Failure` via [ErrorMapper] so the presentation layer only handles the
/// user-safe type — no provider or credential detail leaks.
class DigitalAccessRepositoryImpl implements DigitalAccessRepository {
  DigitalAccessRepositoryImpl(this._dataSource);

  final DigitalAccessDataSource _dataSource;

  @override
  Future<AccessGrant> currentGrant(String reservationId) => _guard(() async {
        final model = await _dataSource.fetchGrant(reservationId);
        return model?.toEntity() ?? AccessGrant.notIssued(reservationId);
      });

  @override
  Future<CheckInResult> checkIn(CheckInRequest request) => _guard(
        () async =>
            CheckInResult.of((await _dataSource.checkIn(request)).toEntity()),
      );

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
