import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../notifications/data/models/app_notification.dart';
import '../../../notifications/data/services/firestore_notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('No hay sesión activa', style: TextStyle(color: Colors.white38)));
    }

    final service = FirestoreNotificationService();

    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Row(children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]).createShader(b),
            child: const Icon(Icons.notifications_rounded, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)]).createShader(b),
            child: const Text('Notificaciones', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => service.markAllAsRead(uid),
            child: Text('Leer todas', style: TextStyle(color: const Color(0xFF6C63FF).withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      // List
      Expanded(
        child: StreamBuilder<List<AppNotification>>(
          stream: service.watchUserNotifications(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_off_outlined, color: Colors.white.withValues(alpha: 0.15), size: 56),
                const SizedBox(height: 12),
                Text('No tienes notificaciones.', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14)),
              ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(
                  notification: n,
                  onTap: () { if (!n.read) service.markAsRead(uid, n.id); },
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, this.onTap});
  final AppNotification notification;
  final VoidCallback? onTap;

  IconData get _icon => switch (notification.type) {
    NotificationType.joinRequestReceived => Icons.person_add_rounded,
    NotificationType.joinRequestApproved => Icons.check_circle_rounded,
    NotificationType.joinRequestRejected => Icons.cancel_rounded,
    NotificationType.inscriptionEdited => Icons.edit_rounded,
    NotificationType.general => Icons.notifications_rounded,
  };

  Color get _iconColor => switch (notification.type) {
    NotificationType.joinRequestReceived => const Color(0xFFFFB347),
    NotificationType.joinRequestApproved => const Color(0xFF22C55E),
    NotificationType.joinRequestRejected => const Color(0xFFFF4D6A),
    NotificationType.inscriptionEdited => const Color(0xFF00D4FF),
    NotificationType.general => const Color(0xFF6C63FF),
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: notification.read ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.07),
          border: Border.all(color: notification.read ? Colors.transparent : _iconColor.withValues(alpha: 0.15)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: _iconColor.withValues(alpha: 0.12)),
            child: Icon(_icon, color: _iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(notification.title, style: TextStyle(color: Colors.white.withValues(alpha: notification.read ? 0.6 : 0.9), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(notification.body, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, height: 1.3)),
            const SizedBox(height: 6),
            Text(DateFormat('dd MMM, HH:mm', 'es').format(notification.createdAt),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
          ])),
          if (!notification.read) Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _iconColor)),
        ]),
      ),
    );
  }
}
