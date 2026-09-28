import 'package:flutter/foundation.dart';

/// Mirrors Laravel's `App\Domain\Notification\Enums\NotificationType` — the
/// reservation lifecycle events the backend notifies the guest about. An
/// unrecognised future value maps to [unknown] instead of failing.
enum GuestNotificationType {
  depositHeld('reservation_deposit_held'),
  identityVerified('identity_verified'),
  checkedIn('reservation_checked_in'),
  invoiced('reservation_invoiced'),
  cancelled('reservation_cancelled'),
  unknown('');

  const GuestNotificationType(this.wireValue);

  final String wireValue;

  static GuestNotificationType fromWire(String? value) =>
      GuestNotificationType.values.firstWhere(
        (GuestNotificationType t) => t != unknown && t.wireValue == value,
        orElse: () => unknown,
      );
}

/// One in-app notification from `GET /guest/notifications`. The copy
/// ([subject] / [body]) is the backend's vetted, localized template text —
/// never composed on the device.
@immutable
class GuestNotification {
  const GuestNotification({
    required this.id,
    required this.reservationId,
    required this.type,
    required this.subject,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String? reservationId;
  final GuestNotificationType type;
  final String subject;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  GuestNotification markedRead() => GuestNotification(
        id: id,
        reservationId: reservationId,
        type: type,
        subject: subject,
        body: body,
        isRead: true,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      other is GuestNotification &&
      other.id == id &&
      other.reservationId == reservationId &&
      other.type == type &&
      other.subject == subject &&
      other.body == body &&
      other.isRead == isRead &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, reservationId, type, subject, body, isRead, createdAt);
}

/// The guest's feed plus the server's unread count (`meta.unread_count`) —
/// the bell badge reads the count, not the page length.
@immutable
class NotificationFeed {
  const NotificationFeed({required this.items, required this.unreadCount});

  static const NotificationFeed empty =
      NotificationFeed(items: <GuestNotification>[], unreadCount: 0);

  final List<GuestNotification> items;
  final int unreadCount;

  @override
  bool operator ==(Object other) =>
      other is NotificationFeed &&
      listEquals(other.items, items) &&
      other.unreadCount == unreadCount;

  @override
  int get hashCode => Object.hash(Object.hashAll(items), unreadCount);
}
