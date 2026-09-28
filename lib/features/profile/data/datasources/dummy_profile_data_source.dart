import '../../../../core/data/data_source.dart';
import '../../domain/entities/guest_preferences.dart';
import 'profile_data_source.dart';

/// Offline/demo settings kept in memory for the session.
class DummyProfileDataSource implements ProfileDataSource, DummyDataSource {
  DummyProfileDataSource({required this.clock});

  final DateTime Function() clock;

  GuestAccountSettings _settings = const GuestAccountSettings(
    preferences: GuestPreferences.defaults,
    dataDeletionRequestedAt: null,
  );

  @override
  Future<GuestAccountSettings> fetchSettings() async => _settings;

  @override
  Future<GuestAccountSettings> savePreferences(GuestPreferences preferences) async =>
      _settings = GuestAccountSettings(
        preferences: preferences,
        dataDeletionRequestedAt: _settings.dataDeletionRequestedAt,
        keepIdentityForFuture: _settings.keepIdentityForFuture,
      );

  @override
  Future<GuestAccountSettings> setIdentityRetention({required bool keepForFuture}) async =>
      _settings = GuestAccountSettings(
        preferences: _settings.preferences,
        dataDeletionRequestedAt: _settings.dataDeletionRequestedAt,
        keepIdentityForFuture: keepForFuture,
      );

  @override
  Future<GuestAccountSettings> requestDataDeletion() async =>
      _settings = GuestAccountSettings(
        preferences: _settings.preferences,
        dataDeletionRequestedAt: _settings.dataDeletionRequestedAt ?? clock(),
        keepIdentityForFuture: _settings.keepIdentityForFuture,
      );
}
