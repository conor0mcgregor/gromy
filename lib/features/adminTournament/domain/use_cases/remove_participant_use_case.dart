import '../../data/repositories/admin_tournament_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RemoveParticipantUseCase  ·  Dominio
//
//  SRP: única responsabilidad → eliminar un participante del torneo.
// ─────────────────────────────────────────────────────────────────────────────

class RemoveParticipantUseCase {
  const RemoveParticipantUseCase(this._repository);

  final AdminTournamentRepository _repository;

  /// Elimina el participante con [participantId] del torneo [tournamentId].
  ///
  /// Lanza [ArgumentError] si algún ID está vacío.
  Future<void> execute({
    required String tournamentId,
    required String participantId,
  }) async {
    if (tournamentId.isEmpty) {
      throw ArgumentError('tournamentId no puede estar vacío.');
    }
    if (participantId.isEmpty) {
      throw ArgumentError('participantId no puede estar vacío.');
    }

    await _repository.removeParticipant(
      tournamentId: tournamentId,
      participantId: participantId,
    );
  }
}
