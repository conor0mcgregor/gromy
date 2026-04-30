import '../../data/repositories/admin_tournament_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DeleteTournamentUseCase  ·  Dominio
//
//  SRP: única responsabilidad → eliminar completamente un torneo.
//  Restricción: solo el creador puede ejecutar esta acción.
// ─────────────────────────────────────────────────────────────────────────────

class DeleteTournamentUseCase {
  const DeleteTournamentUseCase(this._repository);

  final AdminTournamentRepository _repository;

  /// Elimina el torneo y todas sus subcolecciones.
  ///
  /// [callerUid] — UID del usuario que ejecuta la acción.
  /// [creatorUid] — UID del creador del torneo.
  /// Lanza [Exception] si el llamante no es el creador.
  Future<void> execute({
    required String tournamentId,
    required String callerUid,
    required String creatorUid,
  }) async {
    if (callerUid != creatorUid) {
      throw Exception('Solo el creador del torneo puede eliminarlo.');
    }

    if (tournamentId.isEmpty) {
      throw ArgumentError('tournamentId no puede estar vacío.');
    }

    await _repository.deleteTournament(tournamentId);
  }
}
