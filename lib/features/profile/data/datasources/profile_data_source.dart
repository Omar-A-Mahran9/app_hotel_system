import '../../domain/entities/guest_preferences.dart';

/// Contract for the guest's account settings — [ApiProfileDataSource] and
/// [DummyProfileDataSource] behave the same (coding_rules.md §7).
abstract interface class ProfileDataSource {
  Future<GuestAccountSettings> fetchSettings();

  Future<GuestAccountSettings> savePreferences(GuestPreferences preferences);

  Future<GuestAccountSettings> requestDataDeletion();

  Future<GuestAccountSettings> setIdentityRetention({required bool keepForFuture});
}
