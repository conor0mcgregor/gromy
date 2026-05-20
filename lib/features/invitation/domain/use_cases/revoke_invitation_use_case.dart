import '../../data/repositories/invitation_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RevokeInvitationUseCase
// ─────────────────────────────────────────────────────────────────────────────

class RevokeInvitationUseCase {
  const RevokeInvitationUseCase(this._repository);

  final InvitationRepository _repository;

  Future<void> execute(String invitationId) async {
    if (invitationId.trim().isEmpty) {
      throw Exception('ID de invitación inválido.');
    }
    await _repository.revokeInvitation(invitationId.trim());
  }
}
