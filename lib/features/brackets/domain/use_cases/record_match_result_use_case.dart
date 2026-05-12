import '../../data/repositories/bracket_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RecordMatchResultUseCase  ·  Dominio
//
//  Valida y persiste el resultado de un enfrentamiento.
//  La propagación automática del ganador al siguiente round la gestiona
//  la Cloud Function `onMatchWinnerUpdated` (trigger de Firestore).
// ─────────────────────────────────────────────────────────────────────────────

class RecordMatchResultUseCase {
  const RecordMatchResultUseCase(this._repository);

  final BracketRepository _repository;

  /// Registra el resultado de un match.
  ///
  /// [winnerId] debe ser uno de los dos participantes del match.
  /// Tras la escritura, el trigger `onMatchWinnerUpdated` se encarga de
  /// propagar el ganador al match hijo.
  Future<void> call({
    required String bracketId,
    required String matchId,
    required String winnerId,
    required String loserId,
    required int scoreParticipant1,
    required int scoreParticipant2,
  }) async {
    if (bracketId.isEmpty || matchId.isEmpty) {
      throw ArgumentError('Los IDs de bracket y match son obligatorios.');
    }
    if (winnerId.isEmpty || loserId.isEmpty) {
      throw ArgumentError('El ganador y perdedor son obligatorios.');
    }
    if (scoreParticipant1 < 0 || scoreParticipant2 < 0) {
      throw ArgumentError('Los scores no pueden ser negativos.');
    }

    return _repository.updateMatchResult(
      bracketId: bracketId,
      matchId: matchId,
      winnerId: winnerId,
      loserId: loserId,
      scoreParticipant1: scoreParticipant1,
      scoreParticipant2: scoreParticipant2,
    );
  }
}
