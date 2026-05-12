import '../models/app_bracket.dart';
import '../models/app_match.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BracketRepository  ·  Contrato de dominio
//
//  Define las operaciones sobre brackets y matches.
//  OCP: se extiende con nuevos métodos sin modificar los existentes.
//  DIP: las capas superiores dependen de esta abstracción.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class BracketRepository {
  // ── Brackets ──────────────────────────────────────────────────────────────

  /// Stream en tiempo real de todos los brackets de un torneo.
  Stream<List<AppBracket>> watchBrackets(String tournamentId);

  /// Obtiene un bracket por su ID (lectura puntual).
  Future<AppBracket?> getBracket(String bracketId);

  /// Stream en tiempo real de un bracket específico.
  Stream<AppBracket?> watchBracket(String bracketId);

  // ── Matches ───────────────────────────────────────────────────────────────

  /// Stream en tiempo real de todos los matches de un bracket.
  Stream<List<AppMatch>> watchMatches(String bracketId);

  /// Obtiene todos los matches de un bracket (lectura puntual).
  Future<List<AppMatch>> getMatches(String bracketId);

  /// Actualiza el resultado de un match (score + winner).
  Future<void> updateMatchResult({
    required String bracketId,
    required String matchId,
    required String winnerId,
    required String loserId,
    required int scoreParticipant1,
    required int scoreParticipant2,
  });

  /// Actualiza el horario de un match.
  Future<void> updateMatchSchedule({
    required String bracketId,
    required String matchId,
    required DateTime scheduledAt,
  });

  /// Intercambia participantes entre dos matches (modo draft).
  Future<void> swapParticipants({
    required String bracketId,
    required String matchId1,
    required int slotInMatch1,
    required String matchId2,
    required int slotInMatch2,
  });

  // ── Cloud Functions (delegadas) ───────────────────────────────────────────

  /// Genera el bracket automáticamente via Cloud Function.
  Future<AppBracket> generateBracket({
    required String tournamentId,
    String? categoryId,
  });

  /// Publica el bracket via Cloud Function.
  Future<void> publishBracket({required String bracketId});

  /// Regenera el bracket (solo en estado draft) via Cloud Function.
  Future<AppBracket> regenerateBracket({required String bracketId});
}
