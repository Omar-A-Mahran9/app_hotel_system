import '../entities/guest_preferences.dart';

/// The signed-in guest's preferences and privacy requests.
abstract interface class ProfileRepository {
  Future<GuestAccountSettings> settings();

  Future<GuestAccountSettings> savePreferences(GuestPreferences preferences);

  Future<GuestAccountSettings> requestDataDeletion();

  Future<GuestAccountSettings> setIdentityRetention({required bool keepForFuture});
}
