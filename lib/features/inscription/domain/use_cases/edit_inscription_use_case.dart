import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/registration_form.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/participant/repositories/participant_repository.dart';
import '../../../../database/participant/services/firestore_participant_service.dart';
import '../../../../database/team/repositories/team_repository.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/data/repositories/tournament_repository.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';

enum EditInscriptionBlockReason {
  none,
  deadlineClosed,
  tournamentStarted,
  approvedRequiresReview,
  capacityConflict,
  modalityConflict,
  permissionDenied,
  inactive,
  notFound,
}

extension EditInscriptionBlockReasonMessage on EditInscriptionBlockReason {
  String get message {
    return switch (this) {
      EditInscriptionBlockReason.none => '',
      EditInscriptionBlockReason.deadlineClosed =>
        'No puedes editar esta inscripcion porque el plazo de edicion ha finalizado.',
      EditInscriptionBlockReason.tournamentStarted =>
        'No puedes editar esta inscripcion porque el torneo ya ha comenzado.',
      EditInscriptionBlockReason.approvedRequiresReview =>
        'Esta inscripcion fue aprobada manualmente. Si editas los datos, quedara pendiente de revision.',
      EditInscriptionBlockReason.capacityConflict =>
        'No puedes editar esta inscripcion porque existe un conflicto con el cupo.',
      EditInscriptionBlockReason.modalityConflict =>
        'No puedes editar esta inscripcion porque existe un conflicto con la modalidad.',
      EditInscriptionBlockReason.permissionDenied =>
        'No tienes permisos para editar esta inscripcion.',
      EditInscriptionBlockReason.inactive =>
        'Esta inscripcion ya no puede editarse.',
      EditInscriptionBlockReason.notFound => 'La inscripcion no existe.',
    };
  }
}

class EditInscriptionAvailability {
  const EditInscriptionAvailability({
    required this.canEdit,
    required this.reason,
    this.requiresReviewOnSave = false,
  });

  final bool canEdit;
  final EditInscriptionBlockReason reason;
  final bool requiresReviewOnSave;
}

class EditInscriptionResult {
  const EditInscriptionResult({required this.requiresReview});

  final bool requiresReview;
}

class EditInscriptionUseCase {
  EditInscriptionUseCase({
    ParticipantRepository? participantRepository,
    TournamentRepository? tournamentRepository,
    TeamRepository? teamRepository,
    FirebaseAuth? auth,
  }) : _participantRepo =
           participantRepository ?? FirestoreParticipantService(),
       _tournamentRepo = tournamentRepository ?? FirestoreTournamentService(),
       _teamRepo = teamRepository ?? FirestoreTeamService(),
       _auth = auth ?? FirebaseAuth.instance;

  final ParticipantRepository _participantRepo;
  final TournamentRepository _tournamentRepo;
  final TeamRepository _teamRepo;
  final FirebaseAuth _auth;

  Future<AppParticipant?> getParticipant({
    required String tournamentId,
    required String participantId,
  }) {
    return _participantRepo.getParticipant(
      tournamentId: tournamentId,
      participantId: participantId,
    );
  }

  Future<EditInscriptionAvailability> checkEditable({
    required AppTournament tournament,
    required AppParticipant participant,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const EditInscriptionAvailability(
        canEdit: false,
        reason: EditInscriptionBlockReason.permissionDenied,
      );
    }

    final hasPermission = await _hasPermission(participant, uid);
    if (!hasPermission) {
      return const EditInscriptionAvailability(
        canEdit: false,
        reason: EditInscriptionBlockReason.permissionDenied,
      );
    }

    final now = DateTime.now();
    if (!_isActiveStatus(participant.status)) {
      return const EditInscriptionAvailability(
        canEdit: false,
        reason: EditInscriptionBlockReason.inactive,
      );
    }
    if (!tournament.scheduledAt.isAfter(now)) {
      return const EditInscriptionAvailability(
        canEdit: false,
        reason: EditInscriptionBlockReason.tournamentStarted,
      );
    }
    final deadline = tournament.registrationDeadline;
    if (deadline != null && !deadline.isAfter(now)) {
      return const EditInscriptionAvailability(
        canEdit: false,
        reason: EditInscriptionBlockReason.deadlineClosed,
      );
    }
    if (_hasCapacityConflict(tournament)) {
      return const EditInscriptionAvailability(
        canEdit: false,
        reason: EditInscriptionBlockReason.capacityConflict,
      );
    }
    if (_hasModalityConflict(tournament, participant)) {
      return const EditInscriptionAvailability(
        canEdit: false,
        reason: EditInscriptionBlockReason.modalityConflict,
      );
    }

    final wasManuallyApproved =
        participant.status == ParticipantStatus.approved &&
        participant.approvedBy != null &&
        participant.approvedBy!.trim().isNotEmpty;

    return EditInscriptionAvailability(
      canEdit: true,
      reason: wasManuallyApproved
          ? EditInscriptionBlockReason.approvedRequiresReview
          : EditInscriptionBlockReason.none,
      requiresReviewOnSave: wasManuallyApproved,
    );
  }

  Future<EditInscriptionResult> saveChanges({
    required String tournamentId,
    required String participantId,
    required Map<String, dynamic> registrationValues,
    String? notes,
    String? complementaryInfo,
  }) async {
    final tournament = await _tournamentRepo.getTournament(tournamentId);
    if (tournament == null) {
      throw EditInscriptionException(EditInscriptionBlockReason.notFound);
    }
    final participant = await getParticipant(
      tournamentId: tournamentId,
      participantId: participantId,
    );
    if (participant == null) {
      throw EditInscriptionException(EditInscriptionBlockReason.notFound);
    }

    final availability = await checkEditable(
      tournament: tournament,
      participant: participant,
    );
    if (!availability.canEdit) {
      throw EditInscriptionException(availability.reason);
    }

    final errors = RegistrationFormValidator.validateResponses(
      schema: tournament.registrationForm,
      values: registrationValues,
    );
    if (errors.isNotEmpty) {
      throw Exception(errors.values.first);
    }

    final now = DateTime.now();
    final uid = _auth.currentUser?.uid;
    final requiresReview = availability.requiresReviewOnSave;
    await _participantRepo.updateParticipant(
      tournamentId: tournament.id,
      participantId: participant.id,
      data: {
        'responses': RegistrationFormValidator.buildResponses(
          schema: tournament.registrationForm,
          values: registrationValues,
        ).map((response) => response.toMap()).toList(),
        'notes': _blankToNull(notes),
        'complementaryInfo': _blankToNull(complementaryInfo),
        'updatedAt': Timestamp.fromDate(now),
        'lastEditedAt': Timestamp.fromDate(now),
        'updatedBy': uid,
        'requiresReview': requiresReview,
        'reviewStatus': requiresReview ? 'pending' : participant.reviewStatus,
        'reviewReason': requiresReview
            ? 'Cambios realizados por el usuario tras aprobacion manual.'
            : participant.reviewReason,
        if (requiresReview)
          'status': ParticipantStatus.pendingReview.firestoreValue,
      },
    );

    return EditInscriptionResult(requiresReview: requiresReview);
  }

  Future<bool> _hasPermission(AppParticipant participant, String uid) async {
    if (participant.entityType == ParticipantEntityType.user) {
      return participant.entityId == uid;
    }
    final team = await _teamRepo.getTeam(participant.entityId);
    return team?.isAdmin(uid) ?? false;
  }

  bool _isActiveStatus(ParticipantStatus status) {
    return switch (status) {
      ParticipantStatus.pending ||
      ParticipantStatus.approved ||
      ParticipantStatus.pendingReview ||
      ParticipantStatus.active => true,
      ParticipantStatus.rejected || ParticipantStatus.cancelled => false,
    };
  }

  bool _hasCapacityConflict(AppTournament tournament) {
    if (tournament.maxParticipants <= 0) return false;
    return tournament.participantCount > tournament.maxParticipants;
  }

  bool _hasModalityConflict(
    AppTournament tournament,
    AppParticipant participant,
  ) {
    final expectsTeam =
        tournament.membersPerTeam != null && tournament.membersPerTeam! > 0;
    return expectsTeam
        ? participant.entityType != ParticipantEntityType.team
        : participant.entityType != ParticipantEntityType.user;
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

class EditInscriptionException implements Exception {
  const EditInscriptionException(this.reason);

  final EditInscriptionBlockReason reason;

  @override
  String toString() => reason.message;
}
