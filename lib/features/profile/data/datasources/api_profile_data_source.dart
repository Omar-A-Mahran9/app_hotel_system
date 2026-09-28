import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/guest_preferences.dart';
import 'profile_data_source.dart';

typedef _Json = Map<String, Object?>;

/// `auth:guest`:
///
/// * `GET   /guest/auth/me`                    → `guest.preferences`, `guest.data_deletion_requested_at`
/// * `PATCH /guest/preferences`                → the updated guest
/// * `POST  /guest/privacy/deletion-request`   → the updated guest (idempotent)
class ApiProfileDataSource implements ProfileDataSource, RemoteDataSource {
  ApiProfileDataSource(this._client);

  final ApiClient _client;

  @override
  Future<GuestAccountSettings> fetchSettings() async =>
      _parse(await _client.getJson('/guest/auth/me'));

  @override
  Future<GuestAccountSettings> savePreferences(GuestPreferences preferences) async =>
      _parse(await _client.patchJson(
        '/guest/preferences',
        body: <String, dynamic>{
          'high_floor': preferences.highFloor,
          'extra_pillows': preferences.extraPillows,
          'notifications_enabled': preferences.notificationsEnabled,
        },
      ));

  @override
  Future<GuestAccountSettings> setIdentityRetention({required bool keepForFuture}) async =>
      _parse(await _client.patchJson(
        '/guest/preferences',
        body: <String, dynamic>{
          'identity_retention': keepForFuture ? 'keep_for_future' : 'delete_after_checkout',
        },
      ));

  @override
  Future<GuestAccountSettings> requestDataDeletion() async =>
      _parse(await _client.postJson('/guest/privacy/deletion-request'));

  static GuestAccountSettings _parse(Map<String, dynamic> json) {
    final _Json data = (json['data'] as _Json?) ?? const <String, Object?>{};
    final _Json guest = (data['guest'] as _Json?) ?? const <String, Object?>{};
    final _Json prefs = (guest['preferences'] as _Json?) ?? const <String, Object?>{};
    const GuestPreferences d = GuestPreferences.defaults;
    return GuestAccountSettings(
      preferences: GuestPreferences(
        highFloor: (prefs['high_floor'] as bool?) ?? d.highFloor,
        extraPillows: (prefs['extra_pillows'] as bool?) ?? d.extraPillows,
        notificationsEnabled: (prefs['notifications_enabled'] as bool?) ?? d.notificationsEnabled,
      ),
      dataDeletionRequestedAt:
          DateTime.tryParse((guest['data_deletion_requested_at'] as String?) ?? '')?.toLocal(),
      keepIdentityForFuture: guest['identity_retention'] == 'keep_for_future',
    );
  }
}
