import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/admin_invitation.dart';
import '../../domain/entities/app_notification.dart';
import '../controllers/admin_invitation_controller.dart';
import '../controllers/notifications_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AdminInvitationDetailsScreen  ·  Pantalla de detalle de invitación
//
//  Muestra información completa de una invitación de administrador con:
//  - Portada del torneo (si tiene)
//  - Información del torneo y del invitante
//  - Estado actual de la invitación
//  - Botones Aceptar / Rechazar (solo si está pendiente)
// ─────────────────────────────────────────────────────────────────────────────

class AdminInvitationDetailsScreen extends StatefulWidget {
  const AdminInvitationDetailsScreen({
    super.key,
    required this.notification,
  });

  final AppNotification notification;

  @override
  State<AdminInvitationDetailsScreen> createState() =>
      _AdminInvitationDetailsScreenState();
}

class _AdminInvitationDetailsScreenState
    extends State<AdminInvitationDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final AdminInvitationController _ctrl;
  late final NotificationsController _notifCtrl;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late AdminInvitation _invitation;

  @override
  void initState() {
    super.initState();
    _ctrl = AdminInvitationController();
    _notifCtrl = NotificationsController();
    _ctrl.addListener(_onCtrlChange);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _invitation = AdminInvitation.fromNotificationData(
      notificationId: widget.notification.id,
      data: widget.notification.data,
    );

    // Marcar como leída al abrir
    if (widget.notification.isUnread) {
      _notifCtrl.markNotificationAsRead(widget.notification.id);
    }
    _notifCtrl.markNotificationAsClicked(widget.notification.id);
  }

  void _onCtrlChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onCtrlChange)
      ..dispose();
    _notifCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _handleAccept() async {
    final confirmed = await _showConfirmDialog(
      title: 'Aceptar invitación',
      message:
          '¿Confirmas que quieres ser administrador de "${_invitation.tournamentName}"?\n\n'
          'Podrás gestionar participantes y detalles del torneo.',
      confirmLabel: 'Aceptar',
      confirmColor: const Color(0xFF22C55E),
    );
    if (!confirmed) return;

    final ok = await _ctrl.acceptInvitation(_invitation.notificationId);
    if (ok) {
      setState(() {
        _invitation = _invitation.copyWith(status: InvitationStatus.accepted);
      });
      _showSnack('¡Ahora eres administrador!', isSuccess: true);
    } else {
      _showSnack(_ctrl.errorMessage ?? 'Error al aceptar', isError: true);
    }
  }

  Future<void> _handleReject() async {
    final confirmed = await _showConfirmDialog(
      title: 'Rechazar invitación',
      message:
          '¿Estás seguro de que quieres rechazar la invitación para administrar "${_invitation.tournamentName}"?',
      confirmLabel: 'Rechazar',
      confirmColor: const Color(0xFFEF4444),
      isDestructive: true,
    );
    if (!confirmed) return;

    final ok = await _ctrl.rejectInvitation(_invitation.notificationId);
    if (ok) {
      setState(() {
        _invitation = _invitation.copyWith(status: InvitationStatus.rejected);
      });
      _showSnack('Invitación rechazada.', isError: false);
    } else {
      _showSnack(_ctrl.errorMessage ?? 'Error al rechazar', isError: true);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF12122E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Row(
            children: [
              Icon(
                isDestructive
                    ? Icons.warning_amber_rounded
                    : Icons.shield_rounded,
                color: isDestructive
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: confirmColor),
              child: Text(
                confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
    return result == true;
  }

  void _showSnack(String msg, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildStatusBanner(),
                        const SizedBox(height: 24),
                        _buildInviterSection(),
                        const SizedBox(height: 20),
                        _buildTournamentInfoSection(),
                        const SizedBox(height: 20),
                        _buildPermissionsSection(),
                        if (_invitation.invitedAt != null) ...[
                          const SizedBox(height: 20),
                          _buildMetadataSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom action bar
          if (_invitation.status.isActionable)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActionBar(),
            ),
          // Blocking loader
          if (_ctrl.isBusy)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A1A),
            Color(0xFF12102E),
            Color(0xFF0A0A1A),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final hasPortada = _invitation.tournamentPortadaUrl?.isNotEmpty == true;

    return SliverAppBar(
      expandedHeight: hasPortada ? 220 : 120,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A1A),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Invitación de Admin',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        background: hasPortada
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _invitation.tournamentPortadaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, trace) => _coverPlaceholder(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _coverPlaceholder(),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A4A), Color(0xFF0A0A2A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.shield_rounded,
          size: 56,
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _invitation.status;
    final (color, icon, label) = switch (status) {
      InvitationStatus.pending => (
          const Color(0xFFF59E0B),
          Icons.pending_rounded,
          'Invitación pendiente de respuesta',
        ),
      InvitationStatus.accepted => (
          const Color(0xFF22C55E),
          Icons.check_circle_rounded,
          'Invitación aceptada — Eres administrador',
        ),
      InvitationStatus.rejected => (
          const Color(0xFFEF4444),
          Icons.cancel_rounded,
          'Invitación rechazada',
        ),
      InvitationStatus.expired => (
          const Color(0xFF64748B),
          Icons.timer_off_rounded,
          'Invitación expirada',
        ),
      InvitationStatus.cancelled => (
          const Color(0xFF64748B),
          Icons.block_rounded,
          'Invitación cancelada por el organizador',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviterSection() {
    return _buildCard(
      icon: Icons.person_rounded,
      title: 'Invitado por',
      color: const Color(0xFF6C63FF),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFFA855F7)],
              ),
            ),
            child: Center(
              child: Text(
                _invitation.inviterName.isNotEmpty
                    ? _invitation.inviterName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _invitation.inviterName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Organizador del torneo',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: Color(0xFF6C63FF),
                ),
                SizedBox(width: 4),
                Text(
                  'Creador',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentInfoSection() {
    return _buildCard(
      icon: Icons.emoji_events_rounded,
      title: 'Torneo',
      color: const Color(0xFFF59E0B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _invitation.tournamentName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (_invitation.tournamentDescription?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              _invitation.tournamentDescription!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    final permissions = [
      (Icons.manage_accounts_rounded, 'Gestionar participantes del torneo'),
      (Icons.edit_rounded, 'Editar información del torneo'),
      (Icons.category_rounded, 'Gestionar categorías'),
      (Icons.schedule_rounded, 'Modificar fechas y horarios'),
    ];

    return _buildCard(
      icon: Icons.security_rounded,
      title: 'Permisos que obtendrás',
      color: const Color(0xFF22C55E),
      child: Column(
        children: permissions
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                      ),
                      child: Icon(p.$1, size: 16, color: const Color(0xFF22C55E)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      p.$2,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMetadataSection() {
    final df = DateFormat('d MMMM yyyy, HH:mm', 'es');
    return _buildCard(
      icon: Icons.info_outline_rounded,
      title: 'Detalles',
      color: const Color(0xFF00D4FF),
      child: Column(
        children: [
          if (_invitation.invitedAt != null)
            _MetaRow(
              icon: Icons.schedule_rounded,
              label: 'Fecha de invitación',
              value: df.format(_invitation.invitedAt!),
            ),
          if (_invitation.respondedAt != null)
            _MetaRow(
              icon: Icons.check_rounded,
              label: 'Fecha de respuesta',
              value: df.format(_invitation.respondedAt!),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: color.withValues(alpha: 0.15),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              // Rechazar
              Expanded(
                child: _ActionButton(
                  label: 'Rechazar',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFEF4444),
                  isLoading: _ctrl.action == InvitationAction.rejecting,
                  onTap: _ctrl.isBusy ? null : _handleReject,
                  outlined: true,
                ),
              ),
              const SizedBox(width: 12),
              // Aceptar
              Expanded(
                flex: 2,
                child: _ActionButton(
                  label: 'Aceptar invitación',
                  icon: Icons.check_rounded,
                  color: const Color(0xFF22C55E),
                  isLoading: _ctrl.action == InvitationAction.accepting,
                  onTap: _ctrl.isBusy ? null : _handleAccept,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: outlined
              ? null
              : LinearGradient(
                  colors: onTap != null
                      ? [color, color.withValues(alpha: 0.7)]
                      : [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.2),
                        ],
                ),
          border: outlined
              ? Border.all(
                  color: onTap != null
                      ? color
                      : color.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: outlined || onTap == null
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      outlined ? color : Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: outlined ? color : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: outlined ? color : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
