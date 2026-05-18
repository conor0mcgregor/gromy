import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/participant/repositories/participant_repository.dart';
import '../../../../database/participant/services/firestore_participant_service.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../../../features/inscription/domain/models/registration_response.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  EditInscriptionUseCase  ·  Dominio
//
//  Encapsula las reglas de negocio para editar una inscripción existente.
//  Valida plazos, permisos, y marca revisión si el cambio afecta elegibilidad.
// ─────────────────────────────────────────────────────────────────────────────

class EditInscriptionUseCase {
  EditInscriptionUseCase({
    ParticipantRepository? participantRepository,
  }) : _participantRepo =
            participantRepository ?? FirestoreParticipantService();

  final ParticipantRepository _participantRepo;

  /// Verifica si la inscripción puede ser editada.
  /// Devuelve null si es editable, o un mensaje de error si no.
  String? canEdit({
    required AppTournament tournament,
    required AppParticipant participant,
    required String currentUserId,
  }) {
    // 1. El torneo no debe haber comenzado.
    if (tournament.hasStarted) {
      return 'No puedes editar esta inscripción porque el torneo ya ha comenzado.';
    }

    // 2. El plazo de inscripción/edición no debe haber terminado.
    if (tournament.isRegistrationClosed) {
      return 'No puedes editar esta inscripción porque el plazo de edición ha finalizado.';
    }

    // 3. La inscripción debe estar activa.
    if (participant.status == ParticipantStatus.rejected) {
      return 'Esta inscripción ha sido rechazada y no puede editarse.';
    }

    // 4. El usuario debe tener permiso sobre la inscripción.
    if (participant.entityType == ParticipantEntityType.user &&
        participant.entityId != currentUserId) {
      return 'No tienes permiso para editar esta inscripción.';
    }

    return null;
  }

  /// Ejecuta la edición de la inscripción.
  Future<AppParticipant> execute({
    required AppTournament tournament,
    required AppParticipant participant,
    required String currentUserId,
    required List<RegistrationResponse> updatedResponses,
    String? updatedCategoryId,
  }) async {
    // Validar que la inscripción sigue siendo editable.
    final error = canEdit(
      tournament: tournament,
      participant: participant,
      currentUserId: currentUserId,
    );
    if (error != null) {
      throw Exception(error);
    }

    // Verificar si el torneo no comenzó entre carga y guardado.
    if (tournament.hasStarted) {
      throw Exception(
        'El torneo ha comenzado mientras editabas. No se pueden guardar cambios.',
      );
    }

    // Determinar si el cambio requiere revisión.
    final categoryChanged = updatedCategoryId != null &&
        updatedCategoryId != participant.categoryId;
    final needsReview =
        categoryChanged && participant.status == ParticipantStatus.approved;

    final now = DateTime.now();
    final updated = participant.copyWith(
      responses: updatedResponses,
      categoryId: updatedCategoryId ?? participant.categoryId,
      updatedAt: now,
      updatedBy: currentUserId,
      lastEditedAt: now,
      requiresReview: needsReview,
      reviewReason:
          needsReview ? 'Categoría modificada tras aprobación.' : null,
      status: needsReview ? ParticipantStatus.pendingReview : participant.status,
    );

    await _participantRepo.updateParticipant(
      tournamentId: tournament.id,
      participant: updated,
    );

    return updated;
  }
}
