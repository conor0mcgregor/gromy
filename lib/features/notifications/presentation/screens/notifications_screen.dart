import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/notifications_controller.dart';
import '../navigation/notification_navigation_handler.dart';
import '../widgets/admin_invitation_card.dart';
import '../widgets/notification_card.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';
import 'admin_invitation_details_screen.dart';
import 'team_invitation_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationsScreen  ·  Pantalla principal de notificaciones
//
//  Muestra la lista de notificaciones en tiempo real con:
//  - Estado de carga (shimmer)
//  - Estado vacío (ilustración)
//  - Estado de error
//  - Acciones: marcar todas como leídas, eliminar todas
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.controller});

  final NotificationsController controller;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  late final NotificationsController _controller = widget.controller;  String? _userId;
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChanged);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      _controller.init(_userId!);
    }
  }

  void _onStateChanged() {
    if (_controller.state == NotificationsState.loaded ||
        _controller.state == NotificationsState.empty) {
      _fadeController.forward();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          // Título con gradiente
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
            ).createShader(b),
            child: const Text(
              'Notificaciones',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (_controller.unreadCount > 0) ...[
            const SizedBox(width: 10),
            _buildBadge(),
          ],
          const Spacer(),
          // Menú de acciones
          if (_controller.state == NotificationsState.loaded)
            PopupMenuButton<_MenuAction>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              color: const Color(0xFF1A1A3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              onSelected: (action) => _handleMenuAction(action),
              itemBuilder: (_) => [
                _buildMenuItem(
                  _MenuAction.markAllRead,
                  Icons.done_all_rounded,
                  'Marcar todas como leídas',
                ),
                _buildMenuItem(
                  _MenuAction.deleteAll,
                  Icons.delete_sweep_rounded,
                  'Eliminar todas',
                  isDestructive: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFFA855F7)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '${_controller.unreadCount}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  PopupMenuEntry<_MenuAction> _buildMenuItem(
    _MenuAction value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDestructive
                ? const Color(0xFFEF4444)
                : Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDestructive
                  ? const Color(0xFFEF4444)
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contenido principal ────────────────────────────────────────────────────

  Widget _buildContent() {
    return switch (_controller.state) {
      NotificationsState.loading => _buildLoading(),
      NotificationsState.empty => _buildEmpty(),
      NotificationsState.error => _buildError(),
      NotificationsState.loaded => _buildList(),
    };
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (_, index) => _ShimmerNotificationCard(
        delay: index * 100,
      ),
    );
  }

  Widget _buildEmpty() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF).withValues(alpha: 0.15),
                      const Color(0xFF00D4FF).withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                  ).createShader(b),
                  child: const Icon(
                    Icons.notifications_off_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Todo al día',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No tienes notificaciones pendientes.\nTe avisaremos cuando haya novedades.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _controller.errorMessage ?? 'Ha ocurrido un error inesperado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                if (_userId != null) _controller.init(_userId!);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        physics: const BouncingScrollPhysics(),
        itemCount: _controller.notifications.length,
        itemBuilder: (context, index) {
          final notification = _controller.notifications[index];

          // Usar tarjeta especializada para invitaciones de administrador
          if (notification.type == NotificationType.adminInvitation) {
            return AdminInvitationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onDismiss: () =>
                  _controller.removeNotification(notification.id),
            );
          }

          return NotificationCard(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _controller.removeNotification(notification.id),
            onMarkAsRead: notification.isUnread
                ? () => _controller.markNotificationAsRead(notification.id)
                : null,
          );
        },
      ),
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _handleNotificationTap(AppNotification notification) {
    // Marcar como leída y clickeada
    if (notification.isUnread) {
      _controller.markNotificationAsRead(notification.id);
    }
    _controller.markNotificationAsClicked(notification.id);

    // Navegación especializada para invitaciones de administrador
    if (notification.type == NotificationType.adminInvitation) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminInvitationDetailsScreen(notification: notification),
        ),
      );
      return;
    }

    // Navegación especializada para invitaciones de equipo
    if (notification.type == NotificationType.teamInvitation) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TeamInvitationDetailsScreen(notification: notification),
        ),
      );
      return;
    }

    // Intentar navegación contextual genérica
    NotificationNavigationHandler.instance.navigate(context, notification);
  }

  void _handleMenuAction(_MenuAction action) {
    if (_userId == null) return;

    switch (action) {
      case _MenuAction.markAllRead:
        _controller.markAllNotificationsAsRead(_userId!);
      case _MenuAction.deleteAll:
        _showDeleteAllConfirmation();
    }
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        title: Text(
          'Eliminar todas',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar todas las notificaciones? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (_userId != null) {
                _controller.removeAllNotifications(_userId!);
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Enum de acciones del menú ────────────────────────────────────────────────

enum _MenuAction { markAllRead, deleteAll }

// ── Shimmer card para estado de carga ────────────────────────────────────────

class _ShimmerNotificationCard extends StatefulWidget {
  const _ShimmerNotificationCard({this.delay = 0});

  final int delay;

  @override
  State<_ShimmerNotificationCard> createState() =>
      _ShimmerNotificationCardState();
}

class _ShimmerNotificationCardState extends State<_ShimmerNotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _shimmerController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        final opacity = 0.04 + (_shimmerAnimation.value * 0.04);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: opacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon placeholder
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: opacity),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: opacity),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: opacity * 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: opacity * 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
