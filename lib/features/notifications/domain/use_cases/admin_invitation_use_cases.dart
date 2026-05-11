import '../repositories/admin_invitation_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Admin Invitation Use Cases  ·  Capa de dominio
//
//  Cada use case encapsula una única operación de negocio (SRP).
//  Dependen de la abstracción [AdminInvitationRepository] (DIP).
// ─────────────────────────────────────────────────────────────────────────────

/// Envía una invitación de administrador mediante Cloud Function.
class SendAdminInvitationUseCase {
  const SendAdminInvitationUseCase(this._repository);
  final AdminInvitationRepository _repository;

  Future<void> call({
    required String tournamentId,
    required String invitedUserId,
  }) {
    return _repository.sendInvitation(
      tournamentId: tournamentId,
      invitedUserId: invitedUserId,
    );
  }
}

/// Acepta una invitación de administrador.
class AcceptAdminInvitationUseCase {
  const AcceptAdminInvitationUseCase(this._repository);
  final AdminInvitationRepository _repository;

  Future<void> call({required String notificationId}) {
    return _repository.acceptInvitation(notificationId: notificationId);
  }
}

/// Rechaza una invitación de administrador.
class RejectAdminInvitationUseCase {
  const RejectAdminInvitationUseCase(this._repository);
  final AdminInvitationRepository _repository;

  Future<void> call({required String notificationId}) {
    return _repository.rejectInvitation(notificationId: notificationId);
  }
}

/// Cancela una invitación pendiente (solo el creador del torneo).
class CancelAdminInvitationUseCase {
  const CancelAdminInvitationUseCase(this._repository);
  final AdminInvitationRepository _repository;

  Future<void> call({required String notificationId}) {
    return _repository.cancelInvitation(notificationId: notificationId);
  }
}
