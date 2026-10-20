import '../models/local_tournament.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalTournamentRepository  ·  Abstract Interface
//
//  Contrato de dominio para el repositorio de torneos locales.
//  DIP: las capas superiores dependen de esta abstracción.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class LocalTournamentRepository {
  /// Devuelve todos los torneos locales almacenados.
  Future<List<LocalTournament>> getAllTournaments();

  /// Devuelve un torneo por su ID, o null si no existe.
  Future<LocalTournament?> getTournamentById(String id);

  /// Guarda un torneo (crea o actualiza).
  Future<void> saveTournament(LocalTournament tournament);

  /// Elimina un torneo por su ID.
  Future<void> deleteTournament(String id);
}
