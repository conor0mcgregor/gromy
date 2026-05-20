import '../models/app_invitation.dart';
import '../../domain/models/invitation_validation_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  InvitationRepository  ·  Contrato de dominio
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class InvitationRepository {
  /// Crea una nueva invitación para el torneo privado indicado.
  ///
  /// Solo puede llamarse por el organizador del torneo.
  /// El token generado es el ID del documento Firestore (UUID seguro).
  Future<AppInvitation> createInvitation({
    required String tournamentId,
    required String createdByUid,
  });

  /// Obtiene la invitación por su token. Devuelve null si no existe.
  Future<AppInvitation?> getInvitationByToken(String token);

  /// Valida un token y devuelve el resultado sellado correspondiente.
  ///
  /// Nunca lanza excepciones al llamador; encapsula todos los errores
  /// en los subtipos de [InvitationValidationResult].
  Future<InvitationValidationResult> validateInvitation(String token);

  /// Revoca una invitación existente (marca `revoked = true`).
  ///
  /// Solo puede ejecutarse por el creador de la invitación.
  Future<void> revokeInvitation(String invitationId);
}
