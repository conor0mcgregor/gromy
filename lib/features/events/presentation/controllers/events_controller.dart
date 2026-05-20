import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/data/repositories/tournament_repository.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';
import '../../../inscription/domain/use_cases/cancel_enrollment_use_case.dart';

class EventsController {
  EventsController({
    TournamentRepository? tournamentRepository,
    FirebaseAuth? auth,
  }) : _tournamentRepository = tournamentRepository,
       _authOverride = auth;

  final TournamentRepository? _tournamentRepository;
  final FirebaseAuth? _authOverride;

  FirebaseAuth? get _authSafe {
    if (_authOverride != null) return _authOverride;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String? get currentUid {
    try {
      return _authSafe?.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Stream con los torneos en los que el usuario autenticado está inscrito.
  Stream<List<AppTournament>> watchEnrolledTournaments() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    try {
      final repository = _tournamentRepository ?? FirestoreTournamentService();
      return repository.watchEnrolledTournaments(uid);
    } catch (e) {
      return Stream<List<AppTournament>>.error(e);
    }
  }

  /// Cancela la inscripción del usuario en un torneo.
  ///
  /// Lanza [Exception] si la inscripción ya no existe o hay problemas de concurrencia.
  Future<void> cancelInscription({
    required String tournamentId,
    required String participantId,
  }) {
    final repository = _tournamentRepository ?? FirestoreTournamentService();
    final useCase = CancelEnrollmentUseCase(repository);
    return useCase.execute(
      tournamentId: tournamentId,
      participantId: participantId,
    );
  }
}
