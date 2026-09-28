import '../entities/guest_notification.dart';

/// The guest's in-app notification feed. Errors surface as `Failure`s.
abstract interface class NotificationsRepository {
  Future<NotificationFeed> feed();

  Future<GuestNotification> markRead(String notificationId);

  /// Returns how many rows were marked read.
  Future<int> markAllRead();
}
