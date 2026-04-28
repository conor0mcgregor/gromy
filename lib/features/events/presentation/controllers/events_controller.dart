import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/data/repositories/tournament_repository.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';

class EventsController {
  EventsController({
    TournamentRepository? tournamentRepository,
    FirebaseAuth? auth,
  })  : _tournamentRepository =
            tournamentRepository ?? FirestoreTournamentService(),
        _authOverride = auth;

  final TournamentRepository _tournamentRepository;
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

  Stream<List<AppTournament>> watchMyTournaments() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return _tournamentRepository.watchMyTournaments(uid);
  }

  Stream<List<AppTournament>> watchTournamentsAdmin() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return _tournamentRepository.watchTournamentsAdmin(uid);
  }

  /// Stream con los torneos en los que el usuario autenticado está inscrito.
  Stream<List<AppTournament>> watchEnrolledTournaments() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return _tournamentRepository.watchEnrolledTournaments(uid);
  }

  /// Cancela la inscripción del usuario en un torneo.
  ///
  /// Lanza [Exception] si la inscripción ya no existe.
  Future<void> cancelInscription({
    required String tournamentId,
    required String participantId,
  }) {
    return _tournamentRepository.cancelInscription(
      tournamentId: tournamentId,
      participantId: participantId,
    );
  }
}
