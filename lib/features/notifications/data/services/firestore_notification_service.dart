import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreNotificationService  ·  Capa de datos
//
//  Colección: users/{userId}/notifications/{notificationId}
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreNotificationService implements NotificationRepository {
  FirestoreNotificationService({FirebaseFirestore? firestore})
      : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

  @override
  Future<void> createNotification(AppNotification notification) async {
    final docRef = _notificationsRef(notification.userId).doc();
    final toSave = AppNotification(
      id: docRef.id,
      userId: notification.userId,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      data: notification.data,
      createdAt: DateTime.now(),
    );
    await docRef.set(toSave.toMap()).timeout(const Duration(seconds: 10));
  }

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    await _notificationsRef(userId)
        .doc(notificationId)
        .update({'read': true})
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notificationsRef(userId)
        .where('read', isEqualTo: false)
        .get()
        .timeout(const Duration(seconds: 10));

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _notificationsRef(userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
