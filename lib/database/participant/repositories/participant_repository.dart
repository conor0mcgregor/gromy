import '../models/app_participant.dart';
import '../../../../features/inscription/domain/models/registration_response.dart';

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
    List<RegistrationResponse> responses,
    int? registrationFormVersion,
    String? approvedBy,
    String? source,
  });

  /// Devuelve un stream en tiempo real con todos los participantes del torneo.
  Stream<List<AppParticipant>> watchParticipants(String tournamentId);

  /// Obtiene la lista de participantes una sola vez (lectura puntual).
  Future<List<AppParticipant>> getParticipants(String tournamentId);

  /// Obtiene un participante por su entityId dentro de un torneo.
  Future<AppParticipant?> getParticipantByEntity({
    required String tournamentId,
    required String entityId,
  });

  /// Actualiza el estado de la inscripción de un participante.
  Future<void> updateStatus({
    required String tournamentId,
    required String participantId,
    required ParticipantStatus status,
  });

  /// Actualiza todos los campos de un participante.
  Future<void> updateParticipant({
    required String tournamentId,
    required AppParticipant participant,
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
}
