import '../../data/models/app_invitation.dart';
import '../../data/repositories/invitation_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CreateInvitationUseCase
//
//  Valida que el solicitante sea el organizador antes de crear la invitación.
// ─────────────────────────────────────────────────────────────────────────────

class CreateInvitationUseCase {
  const CreateInvitationUseCase(this._repository);

  final InvitationRepository _repository;

  /// Crea un enlace de invitación para [tournamentId].
  ///
  /// Lanza [Exception] si [requestingUid] es vacío (no autenticado).
  /// La autorización de que solo el organizador puede generar links debe
  /// verificarse en la UI/controller antes de llamar a este use case, y
  /// también se refuerza en las reglas de Firestore.
  Future<AppInvitation> execute({
    required String tournamentId,
    required String requestingUid,
  }) async {
    if (requestingUid.isEmpty) {
      throw Exception('Debes iniciar sesión para generar un enlace.');
    }
    if (tournamentId.isEmpty) {
      throw Exception('ID de torneo inválido.');
    }

    return _repository.createInvitation(
      tournamentId: tournamentId,
      createdByUid: requestingUid,
    );
  }
}
