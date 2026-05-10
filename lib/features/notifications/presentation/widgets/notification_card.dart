import 'package:flutter/material.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationCard  ·  Widget reutilizable
//
//  Renderiza una notificación con estilo visual diferenciado según su tipo.
//  Soporta estados leído/no leído, timestamp relativo, swipe-to-dismiss,
//  y navegación contextual.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    this.onMarkAsRead,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback? onMarkAsRead;

  @override
  Widget build(BuildContext context) {
    final config = NotificationTypeConfig.fromType(notification.type);
    final isUnread = notification.isUnread;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: _buildDismissBackground(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: config.color.withValues(alpha: 0.08),
            highlightColor: config.color.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isUnread
                    ? config.color.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: isUnread
                      ? config.color.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
                boxShadow: isUnread
                    ? [
                        BoxShadow(
                          color: config.color.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(config, isUnread),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(config, isUnread),
                        const SizedBox(height: 4),
                        _buildBody(isUnread),
                        const SizedBox(height: 6),
                        _buildFooter(config),
                      ],
                    ),
                  ),
                  if (isUnread) _buildUnreadDot(config),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(NotificationTypeConfig config, bool isUnread) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.color.withValues(alpha: isUnread ? 0.25 : 0.12),
            config.color.withValues(alpha: isUnread ? 0.10 : 0.05),
          ],
        ),
        border: Border.all(
          color: config.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        config.icon,
        color: config.color.withValues(alpha: isUnread ? 1.0 : 0.6),
        size: 20,
      ),
    );
  }

  Widget _buildHeader(NotificationTypeConfig config, bool isUnread) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: config.color.withValues(alpha: 0.12),
          ),
          child: Text(
            config.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: config.color,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            notification.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
              color: Colors.white.withValues(alpha: isUnread ? 0.95 : 0.6),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool isUnread) {
    return Text(
      notification.body,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withValues(alpha: isUnread ? 0.7 : 0.4),
        height: 1.3,
      ),
    );
  }

  Widget _buildFooter(NotificationTypeConfig config) {
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 12,
          color: Colors.white.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 4),
        Text(
          _formatRelativeTime(notification.createdAt),
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        if (notification.actionRoute != null) ...[
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: config.color.withValues(alpha: 0.5),
          ),
        ],
      ],
    );
  }

  Widget _buildUnreadDot(NotificationTypeConfig config) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: config.color,
          boxShadow: [
            BoxShadow(
              color: config.color.withValues(alpha: 0.5),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0x00EF4444), Color(0x33EF4444)],
        ),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Color(0xFFEF4444),
        size: 24,
      ),
    );
  }

  /// Formatea una fecha como tiempo relativo legible.
  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} sem';
    if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} mes';
    return 'Hace ${(diff.inDays / 365).floor()} año';
  }
}
