import 'package:image_picker/image_picker.dart';

import '../../../../core/models/registration_form.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../model/app_tournament.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TournamentRepository  ·  Contrato de dominio
//
//  OCP: se extiende con nuevos métodos sin modificar los existentes ni romper
//  implementaciones anteriores.
//  ISP: los métodos de participantes se delegan a [ParticipantRepository]; aquí
//  sólo se exponen conveniencias de alto nivel que combinan torneo+participante.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class TournamentRepository {
  // ── Creación ───────────────────────────────────────────────────────────────

  /// Crea un torneo sin imagen de portada.
  Future<AppTournament> createTournament(AppTournament tournament);

  /// Crea un torneo subiendo primero [coverImage] a Storage y obteniendo su
  /// URL para asignarla al campo `portadaUrl` antes de persistir en Firestore.
  ///
  /// El [tournament] debe tener `id` vacío; el repositorio generará el ID.
  Future<AppTournament> createTournamentWithCover({
    required AppTournament tournament,
    required XFile coverImage,
  });

  // ── Lectura ────────────────────────────────────────────────────────────────

  /// Devuelve un stream en tiempo real con todos los torneos.
  Stream<List<AppTournament>> watchTournaments();

  /// Devuelve un stream con los torneos en los que [uid] es creador.
  Stream<List<AppTournament>> watchMyTournaments(String uid);

  /// Devuelve un stream con los torneos en los que [uid] es administrador.
  Stream<List<AppTournament>> watchTournamentsAdmin(String uid);

  /// Obtiene un torneo por ID desde colecciones públicas o privadas.
  Future<AppTournament?> getTournament(String tournamentId);

  // ── Participantes (conveniencias de alto nivel) ────────────────────────────

  /// Inscribe una entidad al torneo.
  ///
  /// Devuelve el [AppParticipant] persistido.
  /// Lanza [Exception] si la entidad ya está inscrita o el torneo está lleno.
  Future<AppParticipant> joinTournament({
    required String tournamentId,
    required String entityId,
    required ParticipantEntityType entityType,
    ParticipantStatus status,
    String? categoryId,
    int registrationFormVersion,
    List<RegistrationResponse> registrationResponses,
  });

  /// Devuelve todos los participantes del torneo (lectura puntual).
  Future<List<AppParticipant>> getParticipants(String tournamentId);

  /// Devuelve un stream en tiempo real con los participantes del torneo.
  Stream<List<AppParticipant>> watchParticipants(String tournamentId);

  /// Devuelve un stream con los torneos en los que [uid] está inscrito.
  Stream<List<AppTournament>> watchEnrolledTournaments(String uid);

  /// Cancela la inscripción de un participante en un torneo.
  Future<void> cancelInscription({
    required String tournamentId,
    required String participantId,
  });

  /// Incrementa el contador de participantes del torneo.
  Future<void> incrementParticipantCount(String tournamentId);

  /// Decrementa el contador de participantes del torneo.
  Future<void> decrementParticipantCount(String tournamentId);

  // ── Validación de duplicados ───────────────────────────────────────────────

  /// Busca un torneo existente que coincida exactamente en fecha/hora de inicio
  /// y lugar (cadena normalizada).
  ///
  /// Devuelve el [AppTournament] duplicado si existe, o `null` si no hay aviso.
  Future<AppTournament?> findDuplicateTournament({
    required DateTime scheduledAt,
    required String location,
  });
}
