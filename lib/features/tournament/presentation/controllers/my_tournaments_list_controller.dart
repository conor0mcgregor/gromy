import 'package:rxdart/rxdart.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/model/app_tournament.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../data/services/firestore_tournament_service.dart';

class MyTournamentsListController {
  MyTournamentsListController({
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

  Stream<List<AppTournament>> watchAdministeredTournaments() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    try {
      final repository = _tournamentRepository ?? FirestoreTournamentService();
      return Rx.combineLatest2<
            List<AppTournament>,
            List<AppTournament>,
            List<AppTournament>
          >(
            repository.watchMyTournaments(uid),
            repository.watchTournamentsAdmin(uid),
            (myList, adminList) {
              final combined = [...myList, ...adminList];
              final uniqueIds = <String>{};
              final result = <AppTournament>[];

              for (final t in combined) {
                if (uniqueIds.add(t.id)) {
                  result.add(t);
                }
              }

              result.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
              return result;
            },
          )
          .distinct();
    } catch (e) {
      return Stream<List<AppTournament>>.error(e);
    }
  }
}
