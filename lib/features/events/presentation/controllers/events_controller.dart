import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/data/repositories/tournament_repository.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';
import '../../../inscription/domain/use_cases/cancel_enrollment_use_case.dart';

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

  /// Combina los torneos creados por el usuario y aquellos en los que es administrador.
  Stream<List<AppTournament>> watchAllAdministeredTournaments() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return Rx.combineLatest2<List<AppTournament>, List<AppTournament>,
        List<AppTournament>>(
      _tournamentRepository.watchMyTournaments(uid),
      _tournamentRepository.watchTournamentsAdmin(uid),
      (myList, adminList) {
        // Combinamos ambas listas y eliminamos duplicados por ID
        final combined = [...myList, ...adminList];
        final uniqueIds = <String>{};
        final result = <AppTournament>[];

        for (final t in combined) {
          if (uniqueIds.add(t.id)) {
            result.add(t);
          }
        }

        // Ordenamos por fecha (más recientes primero)
        result.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return result;
      },
    ).distinct();
  }

  /// Stream con los torneos en los que el usuario autenticado está inscrito.
  Stream<List<AppTournament>> watchEnrolledTournaments() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return _tournamentRepository.watchEnrolledTournaments(uid);
  }

  /// Cancela la inscripción del usuario en un torneo.
  ///
  /// Lanza [Exception] si la inscripción ya no existe o hay problemas de concurrencia.
  Future<void> cancelInscription({
    required String tournamentId,
    required String participantId,
  }) {
    final useCase = CancelEnrollmentUseCase(_tournamentRepository);
    return useCase.execute(
      tournamentId: tournamentId,
      participantId: participantId,
    );
  }
}
