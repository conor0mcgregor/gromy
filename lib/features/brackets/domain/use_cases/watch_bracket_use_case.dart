import '../../data/models/app_bracket.dart';
import '../../data/models/app_match.dart';
import '../../data/repositories/bracket_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  WatchBracketUseCase  ·  Dominio
//
//  Proporciona streams reactivos para bracket y matches.
//  El controller de presentación usa estos streams para mantener
//  la UI actualizada en tiempo real.
// ─────────────────────────────────────────────────────────────────────────────

class WatchBracketUseCase {
  const WatchBracketUseCase(this._repository);

  final BracketRepository _repository;

  /// Stream de todos los brackets de un torneo.
  Stream<List<AppBracket>> watchBrackets(String tournamentId) {
    return _repository.watchBrackets(tournamentId);
  }

  /// Stream de un bracket específico.
  Stream<AppBracket?> watchBracket(String bracketId) {
    return _repository.watchBracket(bracketId);
  }

  /// Stream de todos los matches de un bracket, ordenados por round y orden.
  Stream<List<AppMatch>> watchMatches(String bracketId) {
    return _repository.watchMatches(bracketId);
  }
}
