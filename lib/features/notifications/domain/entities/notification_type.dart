import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationType  ·  Constantes de tipo de notificación
//
//  Se usan Strings en lugar de enums rígidos para permitir que nuevos tipos
//  se añadan desde Cloud Functions sin necesidad de actualizar la app.
//  La clase [NotificationTypeConfig] centraliza la presentación visual.
// ─────────────────────────────────────────────────────────────────────────────

/// Constantes para los tipos de notificación conocidos.
///
/// Nuevos tipos pueden añadirse aquí o crearse desde el backend sin romper
/// el sistema — cualquier tipo desconocido se renderiza como [general].
abstract final class NotificationType {
  static const String general = 'general';
  static const String invitation = 'invitation';
  static const String adminInvitation = 'admin_invitation';
  static const String bracketPublished = 'bracket_published';
  static const String tournamentStarted = 'tournament_started';
  static const String scheduleChange = 'schedule_change';
  static const String adminAdded = 'admin_added';
  static const String system = 'system';
  static const String warning = 'warning';
  static const String error = 'error';
  static const String inscriptionConfirmed = 'inscription_confirmed';
  static const String inscriptionCancelled = 'inscription_cancelled';
  static const String teamInvitation = 'team_invitation';
  static const String tournamentUpdate = 'tournament_update';
  static const String tournamentCancelled = 'tournament_cancelled';
  static const String locationChanged = 'location_changed';
}

/// Configuración visual para cada tipo de notificación.
///
/// Centraliza iconos, colores y prioridad visual en un solo lugar.
/// Para añadir un nuevo tipo solo hay que agregar un caso en [fromType].
class NotificationTypeConfig {
  const NotificationTypeConfig({
    required this.icon,
    required this.color,
    required this.label,
    this.priority = 0,
  });

  final IconData icon;
  final Color color;
  final String label;

  /// Prioridad visual (0 = normal, valores más altos = más prominente).
  final int priority;

  /// Resuelve la configuración visual a partir del tipo String.
  ///
  /// Tipos desconocidos usan la configuración de [NotificationType.general].
  factory NotificationTypeConfig.fromType(String type) {
    return switch (type) {
      NotificationType.adminInvitation => const NotificationTypeConfig(
        icon: Icons.shield_rounded,
        color: Color(0xFFF59E0B),
        label: 'Invitación Admin',
        priority: 4,
      ),
      NotificationType.invitation => const NotificationTypeConfig(
        icon: Icons.mail_rounded,
        color: Color(0xFF6C63FF),
        label: 'Invitación',
        priority: 2,
      ),
      NotificationType.bracketPublished => const NotificationTypeConfig(
        icon: Icons.account_tree_rounded,
        color: Color(0xFF00D4FF),
        label: 'Cuadro publicado',
        priority: 1,
      ),
      NotificationType.tournamentStarted => const NotificationTypeConfig(
        icon: Icons.play_circle_rounded,
        color: Color(0xFF22C55E),
        label: 'Torneo iniciado',
        priority: 3,
      ),
      NotificationType.scheduleChange => const NotificationTypeConfig(
        icon: Icons.schedule_rounded,
        color: Color(0xFFFFB347),
        label: 'Cambio de horario',
        priority: 2,
      ),
      NotificationType.adminAdded => const NotificationTypeConfig(
        icon: Icons.admin_panel_settings_rounded,
        color: Color(0xFFA855F7),
        label: 'Nuevo administrador',
        priority: 1,
      ),
      NotificationType.system => const NotificationTypeConfig(
        icon: Icons.info_rounded,
        color: Color(0xFF3B82F6),
        label: 'Sistema',
        priority: 0,
      ),
      NotificationType.warning => const NotificationTypeConfig(
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFF59E0B),
        label: 'Aviso',
        priority: 2,
      ),
      NotificationType.error => const NotificationTypeConfig(
        icon: Icons.error_rounded,
        color: Color(0xFFEF4444),
        label: 'Error',
        priority: 3,
      ),
      NotificationType.inscriptionConfirmed => const NotificationTypeConfig(
        icon: Icons.check_circle_rounded,
        color: Color(0xFF10B981),
        label: 'Inscripción confirmada',
        priority: 1,
      ),
      NotificationType.inscriptionCancelled => const NotificationTypeConfig(
        icon: Icons.cancel_rounded,
        color: Color(0xFFFF6B9D),
        label: 'Inscripción cancelada',
        priority: 1,
      ),
      NotificationType.teamInvitation => const NotificationTypeConfig(
        icon: Icons.group_add_rounded,
        color: Color(0xFF8B5CF6),
        label: 'Invitación de equipo',
        priority: 2,
      ),
      NotificationType.tournamentUpdate => const NotificationTypeConfig(
        icon: Icons.update_rounded,
        color: Color(0xFF06B6D4),
        label: 'Actualización de torneo',
        priority: 1,
      ),
      NotificationType.tournamentCancelled => const NotificationTypeConfig(
        icon: Icons.cancel_schedule_send_rounded,
        color: Color(0xFFEF4444),
        label: 'Torneo cancelado',
        priority: 4,
      ),
      NotificationType.locationChanged => const NotificationTypeConfig(
        icon: Icons.place_rounded,
        color: Color(0xFFFF9F43),
        label: 'Ubicación actualizada',
        priority: 2,
      ),
      // Tipo desconocido → fallback seguro
      _ => const NotificationTypeConfig(
        icon: Icons.notifications_rounded,
        color: Color(0xFF64748B),
        label: 'Notificación',
        priority: 0,
      ),
    };
  }
}
