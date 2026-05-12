import '../../data/repositories/bracket_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PublishBracketUseCase  ·  Dominio
//
//  Orquesta la publicación de un bracket.
//  La validación de integridad y notificaciones se realizan en la
//  Cloud Function.
// ─────────────────────────────────────────────────────────────────────────────

class PublishBracketUseCase {
  const PublishBracketUseCase(this._repository);

  final BracketRepository _repository;

  /// Publica el bracket haciéndolo visible para todos los usuarios.
  ///
  /// La Cloud Function se encarga de:
  ///   - Validar que el bracket esté en estado draft
  ///   - Validar integridad del árbol de matches
  ///   - Cambiar status a published
  ///   - Enviar notificaciones a participantes
  Future<void> call({required String bracketId}) async {
    if (bracketId.isEmpty) {
      throw ArgumentError('El ID del bracket es obligatorio.');
    }

    return _repository.publishBracket(bracketId: bracketId);
  }
}
