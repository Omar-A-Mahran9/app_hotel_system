import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/guest_notification.dart';
import '../models/notification_models.dart';
import 'notifications_data_source.dart';

/// `auth:guest` feed across all of the guest's reservations:
///
/// * `GET   /guest/notifications`                 → rows + `meta.unread_count`
/// * `PATCH /guest/notifications/{id}/read`       → the row, read
/// * `POST  /guest/notifications/read-all`        → `{marked_read}`
///
/// Recipient scoping is server-side; the app never sends a guest id.
class ApiNotificationsDataSource implements NotificationsDataSource, RemoteDataSource {
  ApiNotificationsDataSource(this._client);

  final ApiClient _client;

  /// The screen shows one page; older rows are rarely useful to a guest.
  static const int _pageSize = 50;

  @override
  Future<NotificationFeed> fetchFeed() async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/notifications',
      query: <String, dynamic>{'per_page': _pageSize},
    );
    final List<Object?> rows = (json['data'] as List<Object?>?) ?? const <Object?>[];
    final Json meta = (json['meta'] as Json?) ?? const <String, Object?>{};
    final List<GuestNotification> items = rows
        .whereType<Json>()
        .map(GuestNotificationModel.fromJson)
        .toList(growable: false);
    return NotificationFeed(
      items: items,
      unreadCount: (meta['unread_count'] as num?)?.toInt() ??
          items.where((GuestNotification n) => !n.isRead).length,
    );
  }

  @override
  Future<GuestNotification> markRead(String notificationId) async {
    final Map<String, dynamic> json =
        await _client.patchJson('/guest/notifications/$notificationId/read');
    return GuestNotificationModel.fromJson(
      (json['data'] as Json?) ?? const <String, Object?>{},
    );
  }

  @override
  Future<int> markAllRead() async {
    final Map<String, dynamic> json =
        await _client.postJson('/guest/notifications/read-all');
    final Json data = (json['data'] as Json?) ?? const <String, Object?>{};
    return (data['marked_read'] as num?)?.toInt() ?? 0;
  }
}
