import '../../domain/entities/guest_notification.dart';

typedef Json = Map<String, Object?>;

/// Parses Laravel's `NotificationResource`.
abstract final class GuestNotificationModel {
  static GuestNotification fromJson(Json json) => GuestNotification(
        id: '${json['id']}',
        reservationId:
            json['reservation_id'] == null ? null : '${json['reservation_id']}',
        type: GuestNotificationType.fromWire(json['type'] as String?),
        subject: (json['subject'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        isRead: (json['is_read'] as bool?) ?? (json['read_at'] != null),
        createdAt: DateTime.tryParse((json['created_at'] as String?) ?? '')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
