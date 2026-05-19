import '../models/app_participant.dart';
import '../../../core/models/registration_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ParticipantRepository  ·  Contrato de dominio
//
//  Define las operaciones sobre la subcolección de participantes de un torneo.
//  OCP: se extiende añadiendo nuevos métodos sin modificar los existentes.
//  DIP: las capas superiores (controllers, BLoC) dependen de esta abstracción,
//       no de la implementación Firestore concreta.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class ParticipantRepository {
  /// Inscribe una entidad (usuario o equipo) al torneo [tournamentId].
  ///
  /// Devuelve el [AppParticipant] persistido con su ID definitivo.
  /// Lanza [Exception] si el torneo está lleno o la entidad ya está inscrita.
  Future<AppParticipant> joinTournament({
    required String tournamentId,
    required String entityId,
    required ParticipantEntityType entityType,
    ParticipantStatus status,
    String? categoryId,
    int registrationFormVersion,
    List<RegistrationResponse> registrationResponses,
  });

  /// Devuelve un stream en tiempo real con todos los participantes del torneo.
  Stream<List<AppParticipant>> watchParticipants(String tournamentId);

  /// Obtiene la lista de participantes una sola vez (lectura puntual).
  Future<List<AppParticipant>> getParticipants(String tournamentId);

  /// Actualiza el estado de la inscripción de un participante.
  Future<void> updateStatus({
    required String tournamentId,
    required String participantId,
    required ParticipantStatus status,
  });

  /// Cancela la inscripción de una entidad en el torneo.
  Future<void> leaveTournament({
    required String tournamentId,
    required String participantId,
  });

  /// Comprueba si la entidad [entityId] ya está inscrita en [tournamentId].
  Future<bool> isEnrolled({
    required String tournamentId,
    required String entityId,
  });

  /// Stream en tiempo real con todos los [AppParticipant] de cualquier torneo
  /// donde `entityId` == [entityId].
  ///
  /// Usa collectionGroup para cruzar todas las subcolecciones `participants`.
  Stream<List<AppParticipant>> watchEnrolledParticipants(String entityId);
}
