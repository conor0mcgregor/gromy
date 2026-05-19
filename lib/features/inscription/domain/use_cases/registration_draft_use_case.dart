import 'package:firebase_auth/firebase_auth.dart';

import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../../../database/team/models/app_team.dart';
import '../models/registration_draft.dart';
import '../../data/repositories/registration_draft_repository.dart';
import '../../data/services/firestore_registration_draft_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RegistrationDraftUseCase  ·  Dominio
//
//  Encapsula toda la lógica de negocio relacionada con los borradores:
//    - Guardar un borrador (sin crear inscripción real).
//    - Recuperar un borrador si el torneo sigue abierto.
//    - Validar si el torneo acepta borradores.
//    - Eliminar un borrador tras inscripción exitosa o descarte manual.
//
//  SRP: sólo gestiona borradores, nunca participa en la inscripción real.
//  DIP: depende de [RegistrationDraftRepository], no de la implementación.
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationDraftUseCase {
  RegistrationDraftUseCase({
    RegistrationDraftRepository? repository,
    FirebaseAuth? auth,
  })  : _repo = repository ?? FirestoreRegistrationDraftService(),
        _auth = auth ?? FirebaseAuth.instance;

  final RegistrationDraftRepository _repo;
  final FirebaseAuth _auth;

  // ── Validación del torneo ──────────────────────────────────────────────────

  /// Devuelve true si el torneo todavía acepta inscripciones y borradores.
  ///
  /// Condiciones que invalidan un borrador:
  ///   1. El deadline de inscripción ya pasó.
  ///   2. El torneo está lleno (no hay plazas libres).
  bool isTournamentStillOpen(AppTournament tournament) {
    final now = DateTime.now();

    // 1. Deadline superado
    if (tournament.registrationDeadline != null &&
        now.isAfter(tournament.registrationDeadline!)) {
      return false;
    }

    // 2. Torneo lleno
    if (tournament.participantCount >= tournament.maxParticipants) {
      return false;
    }

    return true;
  }

  // ── Guardar borrador ───────────────────────────────────────────────────────

  /// Guarda el estado actual del formulario como borrador.
  ///
  /// No valida campos requeridos — el borrador puede estar incompleto.
  /// No crea participante ni reserva plaza.
  ///
  /// Lanza [DraftTournamentClosedException] si el torneo ya no acepta
  /// inscripciones (para feedback al usuario).
  Future<void> saveRegistrationDraft({
    required AppTournament tournament,
    required AppTeam? selectedTeam,
    required String? selectedCategoryId,
    Map<String, dynamic> additionalFieldsData = const {},
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No hay sesión activa.');

    if (!isTournamentStillOpen(tournament)) {
      throw DraftTournamentClosedException(tournamentId: tournament.id);
    }

    final now = DateTime.now();
    final docId = RegistrationDraft.buildId(uid, tournament.id);

    // Intentar recuperar el createdAt original si ya existe un borrador
    RegistrationDraft? existing;
    try {
      existing = await _repo.getRegistrationDraft(uid, tournament.id);
    } catch (_) {}

    final draft = RegistrationDraft(
      id: docId,
      userId: uid,
      tournamentId: tournament.id,
      selectedTeamId: selectedTeam?.id,
      selectedCategoryId: selectedCategoryId,
      additionalFieldsData: additionalFieldsData,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await _repo.saveRegistrationDraft(draft);
  }

  // ── Recuperar borrador ─────────────────────────────────────────────────────

  /// Devuelve el borrador si existe y el torneo sigue abierto.
  ///
  /// Devuelve null si:
  ///   - No hay borrador guardado.
  ///   - El torneo ya no acepta inscripciones.
  ///   - El borrador está corrupto (error de deserialización ignorado por el repo).
  Future<RegistrationDraft?> getRegistrationDraft({
    required String userId,
    required AppTournament tournament,
  }) async {
    if (!isTournamentStillOpen(tournament)) return null;

    final draft = await _repo.getRegistrationDraft(userId, tournament.id);
    if (draft == null) return null;

    // Sanidad básica: el borrador debe pertenecer al usuario y al torneo
    if (draft.userId != userId || draft.tournamentId != tournament.id) {
      return null;
    }

    return draft;
  }

  // ── Verificar existencia ───────────────────────────────────────────────────

  /// Devuelve true si existe un borrador válido para [userId] y [tournament].
  Future<bool> hasValidRegistrationDraft({
    required String userId,
    required AppTournament tournament,
  }) async {
    final draft = await getRegistrationDraft(
      userId: userId,
      tournament: tournament,
    );
    return draft != null;
  }

  // ── Eliminar borrador ──────────────────────────────────────────────────────

  /// Elimina el borrador. Llamar tras inscripción exitosa o descarte manual.
  /// No lanza error si no existía.
  Future<void> deleteRegistrationDraft({
    required String userId,
    required String tournamentId,
  }) async {
    await _repo.deleteRegistrationDraft(userId, tournamentId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Excepciones de dominio
// ─────────────────────────────────────────────────────────────────────────────

class DraftTournamentClosedException implements Exception {
  const DraftTournamentClosedException({required this.tournamentId});
  final String tournamentId;

  @override
  String toString() =>
      'DraftTournamentClosedException: torneo $tournamentId ya no acepta inscripciones.';
}
