import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';
import 'notification_datasource.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreNotificationDatasource  ·  Implementación Firestore
//
//  Accede a la colección `notifications` de Firestore.
//  Cada notificación es un documento independiente (escalable).
//
//  FCM tokens se almacenan en `users/{uid}/fcm_tokens/{tokenId}`.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreNotificationDatasource implements NotificationDatasource {
  FirestoreNotificationDatasource({
    FirebaseFirestore? firestore,
  }) : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  CollectionReference<Map<String, dynamic>> _fcmTokens(String userId) =>
      _db.collection('users').doc(userId).collection('fcm_tokens');

  // ── Lectura en tiempo real ─────────────────────────────────────────────────

  @override
  Stream<List<AppNotification>> watchNotifications({
    required String userId,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      final list = <AppNotification>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          list.add(NotificationModel.fromMap(data));
        } catch (e) {
          // Ignorar documentos con formato incorrecto para no romper el stream.
          print('Error mapeando notificación: $e');
        }
      }
      return list;
    });
  }

  @override
  Stream<int> watchUnreadCount({required String userId}) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ── Escritura ──────────────────────────────────────────────────────────────

  @override
  Future<void> markAsRead({required String notificationId}) async {
    await _notifications.doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAllAsRead({required String userId}) async {
    final batch = _db.batch();
    final unread = await _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  @override
  Future<void> markAsClicked({required String notificationId}) async {
    await _notifications.doc(notificationId).update({
      'clicked': true,
    });
  }

  @override
  Future<void> deleteNotification({required String notificationId}) async {
    await _notifications.doc(notificationId).delete();
  }

  @override
  Future<void> deleteAllNotifications({required String userId}) async {
    final batch = _db.batch();
    final docs = await _notifications
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ── FCM Tokens ─────────────────────────────────────────────────────────────

  @override
  Future<void> saveToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    // Usamos el token como ID para evitar duplicados por dispositivo.
    await _fcmTokens(userId).doc(token).set({
      'token': token,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removeToken({
    required String userId,
    required String token,
  }) async {
    await _fcmTokens(userId).doc(token).delete();
  }
}
