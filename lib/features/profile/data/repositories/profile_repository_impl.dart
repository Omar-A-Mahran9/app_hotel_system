import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/guest_preferences.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_data_source.dart';

/// Coordinates the profile data source; errors become `Failure`s.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._dataSource);

  final ProfileDataSource _dataSource;

  @override
  Future<GuestAccountSettings> settings() => _guard(_dataSource.fetchSettings);

  @override
  Future<GuestAccountSettings> savePreferences(GuestPreferences preferences) =>
      _guard(() => _dataSource.savePreferences(preferences));

  @override
  Future<GuestAccountSettings> setIdentityRetention({required bool keepForFuture}) =>
      _guard(() => _dataSource.setIdentityRetention(keepForFuture: keepForFuture));

  @override
  Future<GuestAccountSettings> requestDataDeletion() =>
      _guard(_dataSource.requestDataDeletion);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
