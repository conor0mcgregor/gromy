// ─────────────────────────────────────────────────────────────────────────────
//  TeamInvitation  ·  Entidad de dominio
//
//  Representa una invitación de equipo embebida dentro de una
//  AppNotification (tipo 'team_invitation').
//
//  Espeja el patrón de AdminInvitation para consistencia arquitectural.
//  Se construye desde los campos `data` de la notificación.
// ─────────────────────────────────────────────────────────────────────────────

import 'admin_invitation.dart';

// Re-exportamos InvitationStatus para que la UI no importe admin_invitation
export 'admin_invitation.dart' show InvitationStatus;

/// Entidad de dominio que representa una invitación de equipo.
///
/// Extraída del campo `data` de una [AppNotification] de tipo `team_invitation`.
class TeamInvitation {
  const TeamInvitation({
    required this.notificationId,
    required this.teamId,
    required this.teamName,
    required this.invitedBy,
    required this.inviterName,
    required this.status,
    this.teamPhotoUrl,
    this.memberCount = 0,
    this.invitedAt,
    this.respondedAt,
  });

  /// ID de la notificación que contiene esta invitación.
  final String notificationId;

  final String teamId;
  final String teamName;
  final String? teamPhotoUrl;
  final String invitedBy;
  final String inviterName;
  final InvitationStatus status;

  /// Número actual de miembros del equipo (incluido el creador).
  final int memberCount;

  final DateTime? invitedAt;
  final DateTime? respondedAt;

  /// Construye una [TeamInvitation] desde el mapa `data` de una notificación.
  factory TeamInvitation.fromNotificationData({
    required String notificationId,
    required Map<String, dynamic> data,
  }) {
    return TeamInvitation(
      notificationId: notificationId,
      teamId: data['teamId'] as String? ?? '',
      teamName: data['teamName'] as String? ?? 'Equipo desconocido',
      teamPhotoUrl: data['teamPhotoUrl'] as String?,
      invitedBy: data['invitedBy'] as String? ?? '',
      inviterName: data['inviterName'] as String? ?? 'Administrador',
      status: InvitationStatus.fromString(data['status'] as String?),
      memberCount: int.tryParse(data['memberCount']?.toString() ?? '0') ?? 0,
      invitedAt: _parseMillis(data['invitedAt']),
      respondedAt: _parseMillis(data['respondedAt']),
    );
  }

  static DateTime? _parseMillis(dynamic value) {
    if (value == null) return null;
    final millis = int.tryParse(value.toString());
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  TeamInvitation copyWith({InvitationStatus? status}) {
    return TeamInvitation(
      notificationId: notificationId,
      teamId: teamId,
      teamName: teamName,
      teamPhotoUrl: teamPhotoUrl,
      invitedBy: invitedBy,
      inviterName: inviterName,
      status: status ?? this.status,
      memberCount: memberCount,
      invitedAt: invitedAt,
      respondedAt: respondedAt,
    );
  }
}
