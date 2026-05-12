import '../../data/models/app_bracket.dart';
import '../../data/repositories/bracket_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  GenerateBracketUseCase  ·  Dominio
//
//  Orquesta la generación de un bracket para un torneo.
//  Delega la lógica compleja en la Cloud Function vía repositorio.
// ─────────────────────────────────────────────────────────────────────────────

class GenerateBracketUseCase {
  const GenerateBracketUseCase(this._repository);

  final BracketRepository _repository;

  /// Genera un bracket para el torneo indicado.
  ///
  /// Si [categoryId] no es null, genera bracket solo para esa categoría.
  /// Lanza [Exception] si el torneo no tiene participantes suficientes o
  /// si ya existe un bracket no-draft.
  Future<AppBracket> call({
    required String tournamentId,
    String? categoryId,
  }) async {
    if (tournamentId.isEmpty) {
      throw ArgumentError('El ID del torneo es obligatorio.');
    }

    return _repository.generateBracket(
      tournamentId: tournamentId,
      categoryId: categoryId,
    );
  }
}
