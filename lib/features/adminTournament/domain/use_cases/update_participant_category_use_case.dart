import '../../data/repositories/admin_tournament_repository.dart';

class UpdateParticipantCategoryUseCase {
  const UpdateParticipantCategoryUseCase(this._repository);

  final AdminTournamentRepository _repository;

  Future<void> execute({
    required String tournamentId,
    required String participantId,
    required String categoryId,
    required List<String> allowedCategories,
  }) async {
    if (tournamentId.isEmpty) {
      throw ArgumentError('tournamentId no puede estar vacío.');
    }
    if (participantId.isEmpty) {
      throw ArgumentError('participantId no puede estar vacío.');
    }
    if (!allowedCategories.contains(categoryId)) {
      throw ArgumentError('La categoría seleccionada no es válida.');
    }

    await _repository.updateParticipantCategory(
      tournamentId: tournamentId,
      participantId: participantId,
      categoryId: categoryId,
    );
  }
}
