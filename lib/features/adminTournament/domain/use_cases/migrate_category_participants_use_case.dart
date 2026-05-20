import '../../data/repositories/admin_tournament_repository.dart';

class MigrateCategoryParticipantsUseCase {
  const MigrateCategoryParticipantsUseCase(this._repository);

  final AdminTournamentRepository _repository;

  Future<int> execute({
    required String tournamentId,
    required String sourceCategory,
    required String targetCategory,
    required List<String> allowedCategories,
  }) async {
    if (tournamentId.isEmpty) {
      throw ArgumentError('tournamentId no puede estar vacío.');
    }
    if (!allowedCategories.contains(sourceCategory)) {
      throw ArgumentError('La categoría origen no pertenece al torneo.');
    }
    if (!allowedCategories.contains(targetCategory)) {
      throw ArgumentError('La categoría destino no pertenece al torneo.');
    }

    return _repository.migrateCategoryParticipants(
      tournamentId: tournamentId,
      sourceCategory: sourceCategory,
      targetCategory: targetCategory,
    );
  }
}
