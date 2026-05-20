import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasource/firestore_notification_datasource.dart';
import '../datasource/notification_datasource.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationRepositoryImpl  ·  Implementación del repositorio
//
//  Conecta el dominio con la fuente de datos concreta.
//  SRP: solo orquesta la comunicación entre capas.
//  DIP: depende de [NotificationDatasource], no de una implementación concreta.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({NotificationDatasource? datasource})
    : _datasource = datasource ?? FirestoreNotificationDatasource();

  final NotificationDatasource _datasource;

  @override
  Stream<List<AppNotification>> watchNotifications({
    required String userId,
    int? limit,
  }) {
    return _datasource.watchNotifications(userId: userId, limit: limit);
  }

  @override
  Stream<int> watchUnreadCount({required String userId}) {
    return _datasource.watchUnreadCount(userId: userId);
  }

  @override
  Future<void> markAsRead({required String notificationId}) {
    return _datasource.markAsRead(notificationId: notificationId);
  }

  @override
  Future<void> markAllAsRead({required String userId}) {
    return _datasource.markAllAsRead(userId: userId);
  }

  @override
  Future<void> markAsClicked({required String notificationId}) {
    return _datasource.markAsClicked(notificationId: notificationId);
  }

  @override
  Future<void> updateNotificationData({
    required String notificationId,
    required Map<String, dynamic> data,
  }) {
    return _datasource.updateNotificationData(
      notificationId: notificationId,
      data: data,
    );
  }

  @override
  Future<void> deleteNotification({required String notificationId}) {
    return _datasource.deleteNotification(notificationId: notificationId);
  }

  @override
  Future<void> deleteAllNotifications({required String userId}) {
    return _datasource.deleteAllNotifications(userId: userId);
  }

  @override
  Future<String> createNotification(AppNotification notification) {
    return _datasource.createNotification(notification);
  }

  @override
  Future<void> saveToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    return _datasource.saveToken(
      userId: userId,
      token: token,
      platform: platform,
    );
  }

  @override
  Future<void> removeToken({required String userId, required String token}) {
    return _datasource.removeToken(userId: userId, token: token);
  }
}
