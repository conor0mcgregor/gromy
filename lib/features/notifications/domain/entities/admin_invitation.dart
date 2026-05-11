// ─────────────────────────────────────────────────────────────────────────────
//  AdminInvitation  ·  Entidad de dominio
//
//  Representa una invitación de administrador embebida dentro de una
//  AppNotification (tipo 'admin_invitation').
//
//  Se construye desde los campos `data` de la notificación para desacoplar
//  la lógica de negocio del modelo de datos.
// ─────────────────────────────────────────────────────────────────────────────

/// Estado de una invitación de administrador.
enum InvitationStatus {
  pending,
  accepted,
  rejected,
  expired,
  cancelled;

  static InvitationStatus fromString(String? value) {
    return switch (value) {
      'accepted' => InvitationStatus.accepted,
      'rejected' => InvitationStatus.rejected,
      'expired' => InvitationStatus.expired,
      'cancelled' => InvitationStatus.cancelled,
      _ => InvitationStatus.pending,
    };
  }

  String get label => switch (this) {
    InvitationStatus.pending => 'Pendiente',
    InvitationStatus.accepted => 'Aceptada',
    InvitationStatus.rejected => 'Rechazada',
    InvitationStatus.expired => 'Expirada',
    InvitationStatus.cancelled => 'Cancelada',
  };

  bool get isActionable => this == InvitationStatus.pending;
}

/// Entidad de dominio que representa una invitación de administrador.
///
/// Extraída del campo `data` de una [AppNotification] de tipo `admin_invitation`.
class AdminInvitation {
  const AdminInvitation({
    required this.notificationId,
    required this.tournamentId,
    required this.tournamentName,
    required this.invitedBy,
    required this.inviterName,
    required this.status,
    this.tournamentPortadaUrl,
    this.tournamentDescription,
    this.invitedAt,
    this.respondedAt,
  });

  /// ID de la notificación que contiene esta invitación.
  final String notificationId;

  final String tournamentId;
  final String tournamentName;
  final String? tournamentPortadaUrl;
  final String? tournamentDescription;
  final String invitedBy;
  final String inviterName;
  final InvitationStatus status;
  final DateTime? invitedAt;
  final DateTime? respondedAt;

  /// Construye una [AdminInvitation] a partir del mapa `data` de una notificación.
  factory AdminInvitation.fromNotificationData({
    required String notificationId,
    required Map<String, dynamic> data,
  }) {
    return AdminInvitation(
      notificationId: notificationId,
      tournamentId: data['tournamentId'] as String? ?? '',
      tournamentName: data['tournamentName'] as String? ?? 'Torneo desconocido',
      tournamentPortadaUrl: data['tournamentPortadaUrl'] as String?,
      tournamentDescription: data['tournamentDescription'] as String?,
      invitedBy: data['invitedBy'] as String? ?? '',
      inviterName: data['inviterName'] as String? ?? 'Administrador',
      status: InvitationStatus.fromString(data['status'] as String?),
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

  AdminInvitation copyWith({InvitationStatus? status}) {
    return AdminInvitation(
      notificationId: notificationId,
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      tournamentPortadaUrl: tournamentPortadaUrl,
      tournamentDescription: tournamentDescription,
      invitedBy: invitedBy,
      inviterName: inviterName,
      status: status ?? this.status,
      invitedAt: invitedAt,
      respondedAt: respondedAt,
    );
  }
}
