import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/guest_notification.dart';
import 'notifications_data_source.dart';

/// Offline/demo feed shaped like the `NOTIFICATIONS_List` board. Read state
/// is kept in memory for the session so mark-read behaves like the API.
class DummyNotificationsDataSource implements NotificationsDataSource, DummyDataSource {
  DummyNotificationsDataSource({required this.clock});

  final DateTime Function() clock;
  List<GuestNotification>? _items;

  List<GuestNotification> get _feed => _items ??= _seed(clock());

  static List<GuestNotification> _seed(DateTime now) => <GuestNotification>[
        GuestNotification(
          id: 'n-5',
          reservationId: 'r-demo',
          type: GuestNotificationType.depositHeld,
          subject: 'تم تأكيد الدفع',
          body: 'تم حجز مبلغ التأمين لحجزك.',
          isRead: false,
          createdAt: now.subtract(const Duration(seconds: 30)),
        ),
        GuestNotification(
          id: 'n-4',
          reservationId: 'r-demo',
          type: GuestNotificationType.identityVerified,
          subject: 'تم التحقق من هويتك',
          body: 'أصبح تسجيل الدخول الرقمي متاحاً.',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        GuestNotification(
          id: 'n-3',
          reservationId: 'r-demo',
          type: GuestNotificationType.checkedIn,
          subject: 'تسجيل الدخول الرقمي جاهز',
          body: 'مفتاح غرفتك الرقمي جاهز.',
          isRead: false,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        GuestNotification(
          id: 'n-2',
          reservationId: 'r-demo',
          type: GuestNotificationType.invoiced,
          subject: 'فاتورتك الإلكترونية جاهزة',
          body: 'يمكنك عرض فاتورتك الآن.',
          isRead: true,
          createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        ),
      ];

  @override
  Future<NotificationFeed> fetchFeed() async => NotificationFeed(
        items: List<GuestNotification>.unmodifiable(_feed),
        unreadCount: _feed.where((GuestNotification n) => !n.isRead).length,
      );

  @override
  Future<GuestNotification> markRead(String notificationId) async {
    final int index = _feed.indexWhere((GuestNotification n) => n.id == notificationId);
    if (index < 0) throw NotFoundException('No notification "$notificationId"');
    final GuestNotification read = _feed[index].markedRead();
    _items = <GuestNotification>[..._feed]..[index] = read;
    return read;
  }

  @override
  Future<int> markAllRead() async {
    final int unread = _feed.where((GuestNotification n) => !n.isRead).length;
    _items = _feed.map((GuestNotification n) => n.markedRead()).toList();
    return unread;
  }
}
