import '../../domain/entities/guest_notification.dart';

/// Contract for the guest notification feed — [ApiNotificationsDataSource]
/// (`/guest/notifications`) and [DummyNotificationsDataSource] honour the
/// same behaviour (coding_rules.md §7).
abstract interface class NotificationsDataSource {
  Future<NotificationFeed> fetchFeed();

  Future<GuestNotification> markRead(String notificationId);

  Future<int> markAllRead();
}
