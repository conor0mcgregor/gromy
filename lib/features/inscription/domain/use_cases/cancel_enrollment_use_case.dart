import '../../../tournament/data/repositories/tournament_repository.dart';

class CancelEnrollmentUseCase {
  const CancelEnrollmentUseCase(this._repository);

  final TournamentRepository _repository;

  /// Cancela la inscripción de un participante en un torneo de forma segura.
  /// Lanza [Exception] si el participante no estaba inscrito o el torneo no existe.
  Future<void> execute({
    required String tournamentId,
    required String participantId,
  }) async {
    return _repository.cancelInscription(
      tournamentId: tournamentId,
      participantId: participantId,
    );
  }
}
