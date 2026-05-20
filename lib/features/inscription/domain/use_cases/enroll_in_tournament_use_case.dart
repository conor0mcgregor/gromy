import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/registration_form.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/participant/repositories/participant_repository.dart';
import '../../../../database/participant/services/firestore_participant_service.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../database/team/repositories/team_repository.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../../../features/user/data/models/app_user.dart';
import '../../../../features/user/data/repositories/user_repository.dart';
import '../../../../features/user/data/services/firestore_user_service.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../../../features/tournament/data/repositories/tournament_repository.dart';
import '../../../../features/tournament/data/services/firestore_tournament_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  EnrollInTournamentUseCase  ·  Dominio
//
//  Encapsula toda la lógica de negocio del flujo de inscripción:
//    1. Obtener datos del usuario autenticado.
//    2. Obtener equipos del usuario (si el torneo es por equipos).
//    3. Validar elegibilidad del equipo.
//    4. Evitar inscripciones duplicadas.
//    5. Persistir el participante en Firestore.
//
//  SRP: esta clase tiene una única responsabilidad → gestionar la inscripción.
//  DIP: depende de abstracciones (repositories), no de implementaciones.
// ─────────────────────────────────────────────────────────────────────────────

class EnrollInTournamentUseCase {
  EnrollInTournamentUseCase({
    ParticipantRepository? participantRepository,
    TeamRepository? teamRepository,
    UserRepository? userRepository,
    TournamentRepository? tournamentRepository,
    FirebaseAuth? auth,
  }) : _participantRepo =
           participantRepository ?? FirestoreParticipantService(),
       _teamRepo = teamRepository ?? FirestoreTeamService(),
       _userRepo = userRepository ?? FirestoreUserService(),
       _tournamentRepo = tournamentRepository ?? FirestoreTournamentService(),
       _auth = auth ?? FirebaseAuth.instance;

  final ParticipantRepository _participantRepo;
  final TeamRepository _teamRepo;
  final UserRepository _userRepo;
  final TournamentRepository _tournamentRepo;
  final FirebaseAuth _auth;

  // ── Obtener usuario autenticado ────────────────────────────────────────────

  /// Devuelve el [AppUser] del usuario actualmente autenticado.
  /// Lanza [Exception] si no hay sesión activa.
  Future<AppUser> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No hay sesión activa.');
    }
    final user = await _userRepo.getUser(firebaseUser.uid);
    if (user == null) {
      throw Exception('Perfil de usuario no encontrado.');
    }
    return user;
  }

  // ── Obtener equipos del usuario ────────────────────────────────────────────

  /// Devuelve los equipos en los que [userId] es miembro.
  Stream<List<AppTeam>> watchUserTeams(String userId) {
    return _teamRepo.watchTeamsByMember(userId);
  }

  // ── Validar equipo ─────────────────────────────────────────────────────────

  /// Valida que [team] cumple las restricciones del [tournament].
  ///
  /// Devuelve null si el equipo es válido, o un mensaje de error si no lo es.
  String? validateTeamEligibility({
    required AppTeam team,
    required AppTournament tournament,
  }) {
    final required = tournament.membersPerTeam;
    if (required != null && required > 0) {
      final actual = team.members.length;
      if (actual < required) {
        return 'El equipo "${team.name}" necesita $required miembros pero solo tiene $actual. '
            'Añade más miembros antes de inscribirte.';
      }
    }
    return null;
  }

  // ── Comprobar duplicado ────────────────────────────────────────────────────

  /// Devuelve true si [entityId] ya está inscrito en [tournamentId].
  Future<bool> isAlreadyEnrolled({
    required String tournamentId,
    required String entityId,
  }) {
    return _participantRepo.isEnrolled(
      tournamentId: tournamentId,
      entityId: entityId,
    );
  }

  // ── Ejecutar inscripción ───────────────────────────────────────────────────

  /// Inscribe una entidad (usuario o equipo) al torneo.
  ///
  /// Parámetros:
  ///   [tournament]  – torneo al que se inscribe.
  ///   [entityId]    – UID del usuario o ID del equipo.
  ///   [entityType]  – tipo de entidad.
  ///   [categoryId]  – categoría elegida (puede ser null).
  ///
  /// Lanza [AlreadyEnrolledException] si ya existe inscripción.
  /// Lanza [Exception] con mensaje descriptivo para otros errores.
  Future<AppParticipant> execute({
    required AppTournament tournament,
    required String entityId,
    required ParticipantEntityType entityType,
    String? categoryId,
    Map<String, dynamic> registrationValues = const {},
  }) async {
    if (!tournament.acceptsRegistrations) {
      throw Exception('Este torneo aún no está disponible para inscripciones.');
    }

    final formErrors = RegistrationFormValidator.validateResponses(
      schema: tournament.registrationForm,
      values: registrationValues,
    );
    if (formErrors.isNotEmpty) {
      throw Exception(formErrors.values.first);
    }

    // 1. Obtener todos los participantes actuales del torneo
    final currentParticipants = await _participantRepo.getParticipants(
      tournament.id,
    );

    // 2. Extraer todos los userIds ya inscritos
    final enrolledUserIds = <String>{};
    for (final p in currentParticipants) {
      if (p.entityType == ParticipantEntityType.user) {
        enrolledUserIds.add(p.entityId);
      } else if (p.entityType == ParticipantEntityType.team) {
        final team = await _teamRepo.getTeam(p.entityId);
        if (team != null) {
          enrolledUserIds.addAll(team.members);
        }
      }
    }

    // 3. Obtener los userIds de la entidad que intenta inscribirse
    final joiningUserIds = <String>{};
    if (entityType == ParticipantEntityType.user) {
      joiningUserIds.add(entityId);
    } else if (entityType == ParticipantEntityType.team) {
      final team = await _teamRepo.getTeam(entityId);
      if (team != null) {
        joiningUserIds.addAll(team.members);
      } else {
        throw Exception('El equipo no existe.');
      }
    }

    // 4. Comprobar intersección para evitar duplicados a nivel de usuario
    final duplicateUsers = joiningUserIds.intersection(enrolledUserIds);
    if (duplicateUsers.isNotEmpty) {
      if (entityType == ParticipantEntityType.team) {
        throw Exception(
          'No se puede inscribir el equipo porque cuenta con al menos un usuario ya inscrito en el torneo.',
        );
      } else {
        throw AlreadyEnrolledException(tournamentId: tournament.id);
      }
    }

    // 5. Comprobar duplicado a nivel de entidad (por seguridad adicional)
    final alreadyIn = await _participantRepo.isEnrolled(
      tournamentId: tournament.id,
      entityId: entityId,
    );
    if (alreadyIn) {
      throw AlreadyEnrolledException(tournamentId: tournament.id);
    }

    // 6. Determinar el estado inicial según el tipo de acceso del torneo.
    final initialStatus = tournament.accessType.name == 'publicOpen'
        ? ParticipantStatus.approved
        : ParticipantStatus.pending;

    // 7. Persistir la inscripción.
    final participant = await _participantRepo.joinTournament(
      tournamentId: tournament.id,
      entityId: entityId,
      entityType: entityType,
      status: initialStatus,
      categoryId: categoryId,
      registrationFormVersion: tournament.registrationForm.version,
      registrationResponses: RegistrationFormValidator.buildResponses(
        schema: tournament.registrationForm,
        values: registrationValues,
      ),
    );

    // 8. Incrementar el contador de participantes del torneo.
    await _tournamentRepo.incrementParticipantCount(tournament.id);

    return participant;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Excepciones de dominio
// ─────────────────────────────────────────────────────────────────────────────

class AlreadyEnrolledException implements Exception {
  const AlreadyEnrolledException({required this.tournamentId});
  final String tournamentId;

  @override
  String toString() =>
      'AlreadyEnrolledException: Ya inscrito en torneo $tournamentId';
}
