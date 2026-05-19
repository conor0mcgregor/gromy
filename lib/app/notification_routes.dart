import 'package:flutter/material.dart';

import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/notifications/domain/entities/notification_type.dart';
import '../../features/notifications/presentation/navigation/notification_navigation_handler.dart';
import '../../features/notifications/presentation/screens/admin_invitation_details_screen.dart';
import '../../features/notifications/presentation/screens/team_invitation_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationRoutes  ·  Registro centralizado de rutas de notificación
//
//  Registra en [NotificationNavigationHandler] todos los routes que las
//  push notifications pueden disparar.
//
//  Por qué es necesario:
//  - Las notificaciones in-app se manejan directamente en NotificationsScreen.
//  - Las push notifications (background/terminated) llaman a
//    NotificationNavigationHandler para navegar.
//  - Sin registro, el sistema registra "No handler" y no navega.
//
//  Llamar a [NotificationRoutes.register] una sola vez durante el inicio
//  de la app (p.ej. en MyApp.build o en AppShell.initState).
// ─────────────────────────────────────────────────────────────────────────────

abstract final class NotificationRoutes {
  /// Registra todos los handlers de navegación de notificaciones.
  static void register() {
    NotificationNavigationHandler.instance.registerRoutes({
      // Invitación de administrador
      '/notification/admin_invitation': _handleAdminInvitation,

      // Invitación de equipo
      '/notification/team_invitation': _handleTeamInvitation,

      // Torneo: detalle genérico (cancelaciones, fechas, ubicación)
      '/tournament/detail': _handleTournamentDetail,

      // Equipo: detalle genérico
      '/team/detail': _handleTeamDetail,
    });
  }

  static void _handleAdminInvitation(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Construir una AppNotification mínima para pasarla a la pantalla
    final notification = _buildMinimalNotification(
      type: NotificationType.adminInvitation,
      data: data,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminInvitationDetailsScreen(notification: notification),
      ),
    );
  }

  static void _handleTeamInvitation(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final notification = _buildMinimalNotification(
      type: NotificationType.teamInvitation,
      data: data,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamInvitationDetailsScreen(notification: notification),
      ),
    );
  }

  static void _handleTournamentDetail(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final tournamentId = data['tournamentId']?.toString() ?? '';
    if (tournamentId.isEmpty) return;

    // Navegar al torneo. Si no hay un contexto de torneo disponible,
    // simplemente mostramos un SnackBar informativo.
    // En una implementación completa se usaría Navigator con rutas nombradas.
    // Por ahora, solo navigamos al index de torneos si está disponible.
    debugPrint('[NotificationRoutes] Navegar a torneo: $tournamentId');
    // TODO: integrar con el sistema de navegación del torneo
  }

  static void _handleTeamDetail(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final teamId = data['teamId']?.toString() ?? '';
    if (teamId.isEmpty) return;

    debugPrint('[NotificationRoutes] Navegar a equipo: $teamId');
    // TODO: integrar con el sistema de navegación de equipos
  }

  /// Construye una [AppNotification] mínima a partir de los datos de push.
  static AppNotification _buildMinimalNotification({
    required String type,
    required Map<String, dynamic> data,
  }) {
    final notificationId = data['notificationId']?.toString() ??
        data['id']?.toString() ??
        '';
    return AppNotification(
      id: notificationId,
      userId: '',
      type: type,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      data: Map<String, dynamic>.from(data),
      createdAt: DateTime.now(),
      read: false,
      clicked: false,
    );
  }
}
