import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../database/team/services/firestore_team_service.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../domain/models/enrollment_status.dart';
import '../../domain/use_cases/check_enrollment_use_case.dart';
import '../../domain/use_cases/cancel_enrollment_use_case.dart';
import '../../domain/use_cases/registration_draft_use_case.dart';

enum PreinscriptionState { loading, loaded, error }

class PreinscriptionController extends ChangeNotifier {
  final String tournamentId;
  final AppTournament? tournament;
  final CheckEnrollmentUseCase _checkUseCase;
  final CancelEnrollmentUseCase _cancelUseCase;
  final RegistrationDraftUseCase _draftUseCase;
  final FirebaseAuth _auth;

  PreinscriptionController({
    required this.tournamentId,
    this.tournament,
    CheckEnrollmentUseCase? checkUseCase,
    CancelEnrollmentUseCase? cancelUseCase,
    RegistrationDraftUseCase? draftUseCase,
    FirebaseAuth? auth,
  })  : _checkUseCase = checkUseCase ??
            CheckEnrollmentUseCase(
              FirestoreTournamentService(),
              FirestoreTeamService(),
            ),
        _cancelUseCase =
            cancelUseCase ?? CancelEnrollmentUseCase(FirestoreTournamentService()),
        _draftUseCase = draftUseCase ?? RegistrationDraftUseCase(),
        _auth = auth ?? FirebaseAuth.instance;

  PreinscriptionState state = PreinscriptionState.loading;
  EnrollmentStatus enrollmentStatus = EnrollmentStatus.notEnrolled();
  String? errorMessage;

  /// true si existe un borrador válido para el usuario y este torneo.
  bool hasDraft = false;

  Future<void> checkEnrollment() async {
    state = PreinscriptionState.loading;
    errorMessage = null;
    hasDraft = false;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      enrollmentStatus = await _checkUseCase.execute(
        tournamentId: tournamentId,
        userId: userId,
      );

      // Comprobar si hay un borrador válido (en paralelo conceptual, ejecutado
      // secuencialmente para evitar complejidad con streams).
      if (userId != null && tournament != null && !enrollmentStatus.isEnrolled) {
        hasDraft = await _draftUseCase.hasValidRegistrationDraft(
          userId: userId,
          tournament: tournament!,
        );
      }

      state = PreinscriptionState.loaded;
    } catch (e) {
      state = PreinscriptionState.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> cancelInscription() async {
    if (enrollmentStatus.participant == null) return;

    await _cancelUseCase.execute(
      tournamentId: tournamentId,
      participantId: enrollmentStatus.participant!.id,
    );

    // Volvemos a comprobar para actualizar la UI
    await checkEnrollment();
  }

  /// Descarta el borrador del usuario para este torneo.
  Future<void> discardDraft() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _draftUseCase.deleteRegistrationDraft(
        userId: userId,
        tournamentId: tournamentId,
      );
    } catch (_) {
      // Ignorar errores de borrado
    }

    hasDraft = false;
    notifyListeners();
  }
}
