import 'admin_invitation.dart';

/// Invitacion pendiente visible desde la gestion del equipo.
class PendingTeamInvitation {
  const PendingTeamInvitation({
    required this.notificationId,
    required this.teamId,
    required this.userId,
    required this.nickname,
    required this.displayName,
    required this.status,
    this.photoUrl,
    this.invitedAt,
  });

  final String notificationId;
  final String teamId;
  final String userId;
  final String nickname;
  final String displayName;
  final String? photoUrl;
  final InvitationStatus status;
  final DateTime? invitedAt;
}
