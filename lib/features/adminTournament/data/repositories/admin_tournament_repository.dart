import '../../../tournament/data/model/app_tournament.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AdminTournamentRepository  ·  Contrato de dominio
//
//  Define las operaciones exclusivas de administración de un torneo.
//  ISP: esta interfaz solo expone operaciones de gestión, separada del
//  TournamentRepository de lectura/creación.
//  DIP: las capas superiores dependen de esta abstracción.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class AdminTournamentRepository {
  // ── Actualización ─────────────────────────────────────────────────────────

  /// Actualiza solo los campos que hayan cambiado entre [original] y [updated].
  Future<void> updateTournament({
    required AppTournament original,
    required AppTournament updated,
  });

  // ── Participantes ─────────────────────────────────────────────────────────

  /// Elimina un participante del torneo y decrementa el contador.
  ///
  /// Usa una transacción para garantizar consistencia.
  Future<void> removeParticipant({
    required String tournamentId,
    required String participantId,
  });

  /// Cambia la categoría de un participante dentro del torneo.
  Future<void> updateParticipantCategory({
    required String tournamentId,
    required String participantId,
    required String categoryId,
  });

  // ── Administradores ───────────────────────────────────────────────────────

  /// Añade un administrador al torneo por su UID.
  ///
  /// Solo el creador puede ejecutar esta operación.
  Future<void> addAdmin({
    required String tournamentId,
    required String adminUid,
  });

  /// Elimina un administrador del torneo.
  ///
  /// Solo el creador puede ejecutar esta operación.
  /// No se permite eliminar al propio creador de la lista.
  Future<void> removeAdmin({
    required String tournamentId,
    required String adminUid,
  });

  // ── Eliminación ───────────────────────────────────────────────────────────

  /// Elimina completamente el torneo, incluyendo su subcolección de
  /// participantes.
  ///
  /// Solo el creador puede ejecutar esta operación.
  Future<void> deleteTournament(String tournamentId);

  // ── Lectura auxiliar ──────────────────────────────────────────────────────

  /// Obtiene un torneo por su ID (lectura puntual).
  Future<AppTournament?> getTournament(String tournamentId);
}
