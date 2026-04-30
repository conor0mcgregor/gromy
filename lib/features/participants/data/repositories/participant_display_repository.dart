// ─────────────────────────────────────────────────────────────────────────────
//  ParticipantDisplayRepository  ·  Interfaz (contrato)
//
//  Define las operaciones de lectura de participantes enriquecidos con sus
//  datos de usuario/equipo resueltos.
//
//  Principio Open/Closed: la UI depende de esta abstracción, no de la
//  implementación concreta de Firestore.
// ─────────────────────────────────────────────────────────────────────────────

import '../models/participant_display.dart';

abstract interface class ParticipantDisplayRepository {
  /// Obtiene todos los participantes de un torneo con sus datos resueltos.
  ///
  /// [tournamentId] — ID del torneo en Firestore.
  ///
  /// Devuelve una lista de [ParticipantDisplay] (UserParticipantDisplay o
  /// TeamParticipantDisplay), ordenados por fecha de inscripción ascendente.
  Future<List<ParticipantDisplay>> getParticipants(String tournamentId);

  /// Vista previa: obtiene solo los primeros [limit] participantes.
  ///
  /// Útil para la vista previa de avatares en la pantalla de detalle,
  /// evitando cargar todos los participantes innecesariamente.
  Future<List<ParticipantDisplay>> getParticipantsPreview(
    String tournamentId, {
    int limit = 7,
  });


}
