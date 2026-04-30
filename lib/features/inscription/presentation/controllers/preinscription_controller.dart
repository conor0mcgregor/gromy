import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../database/team/services/firestore_team_service.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';
import '../../domain/models/enrollment_status.dart';
import '../../domain/use_cases/check_enrollment_use_case.dart';
import '../../domain/use_cases/cancel_enrollment_use_case.dart';

enum PreinscriptionState { loading, loaded, error }

class PreinscriptionController extends ChangeNotifier {
  final String tournamentId;
  final CheckEnrollmentUseCase _checkUseCase;
  final CancelEnrollmentUseCase _cancelUseCase;
  final FirebaseAuth _auth;

  PreinscriptionController({
    required this.tournamentId,
    CheckEnrollmentUseCase? checkUseCase,
    CancelEnrollmentUseCase? cancelUseCase,
    FirebaseAuth? auth,
  })  : _checkUseCase = checkUseCase ?? CheckEnrollmentUseCase(
          FirestoreTournamentService(),
          FirestoreTeamService(),
        ),
        _cancelUseCase = cancelUseCase ?? CancelEnrollmentUseCase(FirestoreTournamentService()),
        _auth = auth ?? FirebaseAuth.instance;

  PreinscriptionState state = PreinscriptionState.loading;
  EnrollmentStatus enrollmentStatus = EnrollmentStatus.notEnrolled();
  String? errorMessage;

  Future<void> checkEnrollment() async {
    state = PreinscriptionState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      enrollmentStatus = await _checkUseCase.execute(
        tournamentId: tournamentId,
        userId: userId,
      );
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
}
