import 'package:flutter/material.dart';

import '../../domain/entities/admin_invitation.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AdminInvitationCard  ·  Widget especializado
//
//  Renderiza una tarjeta de invitación de administrador con:
//  - Estado visual diferenciado (pendiente / aceptada / rechazada)
//  - Información del torneo
//  - Indicador de acción requerida para invitaciones pendientes
//
//  Extiende visualmente al NotificationCard base pero con contenido enriquecido.
// ─────────────────────────────────────────────────────────────────────────────

class AdminInvitationCard extends StatelessWidget {
  const AdminInvitationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final invitation = AdminInvitation.fromNotificationData(
      notificationId: notification.id,
      data: notification.data,
    );

    final config = NotificationTypeConfig.fromType(NotificationType.adminInvitation);
    final isUnread = notification.isUnread;
    final isPending = invitation.status == InvitationStatus.pending;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: _buildDismissBackground(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Material(
          color: Color(0xFF000000).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            splashColor: config.color.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isUnread
                      ? [
                          const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          const Color(0xFFF59E0B).withValues(alpha: 0.04),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                ),
                border: Border.all(
                  color: isUnread
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
                boxShadow: isUnread
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(invitation, isUnread),
                  const SizedBox(height: 10),
                  _buildTournamentRow(invitation),
                  const SizedBox(height: 10),
                  _buildInviterRow(invitation),
                  const SizedBox(height: 10),
                  _buildStatusFooter(invitation, isPending, isUnread),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AdminInvitation invitation, bool isUnread) {
    return Row(
      children: [
        // Ícono de escudo animado
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF59E0B).withValues(alpha: isUnread ? 0.3 : 0.12),
                const Color(0xFFF59E0B).withValues(alpha: isUnread ? 0.12 : 0.05),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.shield_rounded,
            color: const Color(0xFFF59E0B)
                .withValues(alpha: isUnread ? 1.0 : 0.6),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    ),
                    child: const Text(
                      'INVITACIÓN ADMIN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                notification.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isUnread ? FontWeight.w700 : FontWeight.w500,
                  color:
                      Colors.white.withValues(alpha: isUnread ? 0.95 : 0.6),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        if (isUnread) _buildUnreadDot(),
      ],
    );
  }

  Widget _buildTournamentRow(AdminInvitation invitation) {
    return Row(
      children: [
        if (invitation.tournamentPortadaUrl?.isNotEmpty == true)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              invitation.tournamentPortadaUrl!,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, trace) => _tournamentIconBox(),
            ),
          )
        else
          _tournamentIconBox(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invitation.tournamentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Torneo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tournamentIconBox() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        size: 20,
        color: Color(0xFFF59E0B),
      ),
    );
  }

  Widget _buildInviterRow(AdminInvitation invitation) {
    return Row(
      children: [
        Icon(
          Icons.person_rounded,
          size: 14,
          color: Colors.white.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 6),
        Text(
          'Invitado por: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        Expanded(
          child: Text(
            invitation.inviterName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFooter(
    AdminInvitation invitation,
    bool isPending,
    bool isUnread,
  ) {
    final (color, icon, label) = _statusStyle(invitation.status);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (isPending)
          Text(
            'Ver detalles →',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: 0.25),
          ),
      ],
    );
  }

  (Color, IconData, String) _statusStyle(InvitationStatus status) {
    return switch (status) {
      InvitationStatus.pending => (
          const Color(0xFFF59E0B),
          Icons.pending_rounded,
          'Pendiente',
        ),
      InvitationStatus.accepted => (
          const Color(0xFF22C55E),
          Icons.check_circle_rounded,
          'Aceptada',
        ),
      InvitationStatus.rejected => (
          const Color(0xFFEF4444),
          Icons.cancel_rounded,
          'Rechazada',
        ),
      InvitationStatus.expired => (
          const Color(0xFF64748B),
          Icons.timer_off_rounded,
          'Expirada',
        ),
      InvitationStatus.cancelled => (
          const Color(0xFF64748B),
          Icons.block_rounded,
          'Cancelada',
        ),
    };
  }

  Widget _buildUnreadDot() {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF59E0B),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return 'Hace ${(diff.inDays / 7).floor()} sem';
  }
}
