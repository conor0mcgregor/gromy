import 'package:flutter/material.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/team_invitation.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamInvitationCard  ·  Widget especializado para invitaciones de equipo
//
//  Renderiza una tarjeta rica y visual para invitaciones de equipo con:
//  - Avatar grande del equipo con protagonismo visual
//  - Nombre del equipo e invitante
//  - Número de miembros actuales
//  - Estado y fecha de invitación
//  - Botones inline de aceptar/rechazar para invitaciones pendientes
//
//  Clean Architecture: solo presentación, lógica delegada a callbacks.
//  SRP: gestiona únicamente el estado visual de los botones.
// ─────────────────────────────────────────────────────────────────────────────

class TeamInvitationCard extends StatefulWidget {
  const TeamInvitationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  final AppNotification notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  /// Callback asíncrono para aceptar la invitación.
  final Future<bool> Function() onAccept;

  /// Callback asíncrono para rechazar la invitación.
  final Future<bool> Function() onReject;

  @override
  State<TeamInvitationCard> createState() => _TeamInvitationCardState();
}

enum _CardAction { idle, accepting, rejecting }

class _TeamInvitationCardState extends State<TeamInvitationCard>
    with SingleTickerProviderStateMixin {
  _CardAction _action = _CardAction.idle;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isBusy => _action != _CardAction.idle;

  Future<void> _handleAccept() async {
    if (_isBusy) return;
    setState(() => _action = _CardAction.accepting);
    await widget.onAccept();
    if (mounted) setState(() => _action = _CardAction.idle);
  }

  Future<void> _handleReject() async {
    if (_isBusy) return;
    setState(() => _action = _CardAction.rejecting);
    await widget.onReject();
    if (mounted) setState(() => _action = _CardAction.idle);
  }

  @override
  Widget build(BuildContext context) {
    final invitation = TeamInvitation.fromNotificationData(
      notificationId: widget.notification.id,
      data: widget.notification.data,
    );

    final isUnread = widget.notification.isUnread;
    final isPending = invitation.status == InvitationStatus.pending;

    return Dismissible(
      key: ValueKey(widget.notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismiss(),
      background: _buildDismissBackground(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnread
                ? [
                    const Color(0xFF3B82F6).withValues(alpha: 0.18),
                    const Color(0xFF1D4ED8).withValues(alpha: 0.10),
                    const Color(0xFF06B6D4).withValues(alpha: 0.06),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
          ),
          border: Border.all(
            color: isUnread
                ? const Color(0xFF3B82F6).withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              splashColor: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              highlightColor: const Color(0xFF3B82F6).withValues(alpha: 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero: avatar + info ─────────────────────────────────────
                  _buildHeroSection(invitation, isUnread),

                  _buildDivider(),

                  // ── Meta: estado + fecha ────────────────────────────────────
                  _buildMetaRow(invitation),

                  // ── Botones de acción (solo si está pendiente) ──────────────
                  if (isPending) ...[
                    _buildDivider(),
                    _buildActionButtons(),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sección hero ──────────────────────────────────────────────────────────

  Widget _buildHeroSection(TeamInvitation invitation, bool isUnread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamAvatar(invitation, isUnread),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label + timestamp
                Row(
                  children: [
                    _buildTypeLabel(),
                    const Spacer(),
                    Text(
                      _formatTime(widget.notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: 6),
                      _buildUnreadDot(),
                    ],
                  ],
                ),
                const SizedBox(height: 7),

                // Nombre del equipo
                Text(
                  invitation.teamName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(
                      alpha: isUnread ? 0.97 : 0.72,
                    ),
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),

                // Quién invitó
                Row(
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: 13,
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Te invitó ${invitation.inviterName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF60A5FA).withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // Número de miembros
                if (invitation.memberCount > 0) ...[
                  const SizedBox(height: 7),
                  _buildMembersChip(invitation.memberCount),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAvatar(TeamInvitation invitation, bool isUnread) {
    const double size = 72;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: isUnread ? _pulseAnimation.value : 1.0,
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(
                    alpha: isUnread ? 0.5 : 0.2,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: invitation.teamPhotoUrl?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      invitation.teamPhotoUrl!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    ),
                  )
                : _avatarFallback(),
          ),
          // Badge de correo (invitación pendiente)
          if (invitation.status == InvitationStatus.pending)
            Positioned(
              bottom: -3,
              right: -3,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F172A),
                  border: Border.all(
                    color: const Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.mail_rounded,
                  size: 11,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return const Center(
      child: Icon(Icons.groups_rounded, size: 34, color: Colors.white),
    );
  }

  Widget _buildTypeLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
        ),
      ),
      child: const Text(
        'INVITACIÓN EQUIPO',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildUnreadDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3B82F6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '$count ${count == 1 ? 'miembro' : 'miembros'}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Meta row ──────────────────────────────────────────────────────────────

  Widget _buildMetaRow(TeamInvitation invitation) {
    final (color, icon, label) = _statusStyle(invitation.status);
    final dateText = invitation.invitedAt != null
        ? _formatDate(invitation.invitedAt!)
        : _formatTime(widget.notification.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: color),
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
          // Fecha
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 11,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 4),
              Text(
                dateText,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Botones de acción ─────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          // Rechazar
          Expanded(
            child: _ActionButton(
              label: 'Rechazar',
              icon: Icons.close_rounded,
              isLoading: _action == _CardAction.rejecting,
              isDisabled: _isBusy,
              style: _ActionButtonStyle.reject,
              onTap: _handleReject,
            ),
          ),
          const SizedBox(width: 10),
          // Aceptar (más ancho — acción principal)
          Expanded(
            flex: 2,
            child: _ActionButton(
              label: 'Aceptar',
              icon: Icons.check_rounded,
              isLoading: _action == _CardAction.accepting,
              isDisabled: _isBusy,
              style: _ActionButtonStyle.accept,
              onTap: _handleAccept,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dismiss background ────────────────────────────────────────────────────

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.06),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  (Color, IconData, String) _statusStyle(InvitationStatus status) {
    return switch (status) {
      InvitationStatus.pending => (
          const Color(0xFF3B82F6),
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

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return 'Hace ${(diff.inDays / 7).floor()} sem';
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ActionButton  ·  Botón de acción interno reutilizable
// ─────────────────────────────────────────────────────────────────────────────

enum _ActionButtonStyle { accept, reject }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isDisabled,
    required this.style,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isDisabled;
  final _ActionButtonStyle style;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final isAccept = style == _ActionButtonStyle.accept;
    final activeColor =
        isAccept ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final opacity = isDisabled ? 0.45 : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : onTap,
          splashColor: activeColor.withValues(alpha: 0.15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isAccept
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF16A34A).withValues(alpha: 0.85),
                        const Color(0xFF22C55E).withValues(alpha: 0.75),
                      ],
                    )
                  : null,
              color: isAccept
                  ? null
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: activeColor.withValues(alpha: isAccept ? 0.3 : 0.22),
                width: 1,
              ),
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(activeColor),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: activeColor),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isAccept
                              ? Colors.white
                              : activeColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
