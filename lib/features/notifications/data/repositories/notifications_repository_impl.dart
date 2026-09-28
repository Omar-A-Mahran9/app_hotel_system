import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/guest_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_data_source.dart';

/// Coordinates the notifications data source; dummy vs API is a DI decision.
/// Every data-layer error is mapped to a `Failure` via [ErrorMapper].
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._dataSource);

  final NotificationsDataSource _dataSource;

  @override
  Future<NotificationFeed> feed() => _guard(_dataSource.fetchFeed);

  @override
  Future<GuestNotification> markRead(String notificationId) =>
      _guard(() => _dataSource.markRead(notificationId));

  @override
  Future<int> markAllRead() => _guard(_dataSource.markAllRead);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
