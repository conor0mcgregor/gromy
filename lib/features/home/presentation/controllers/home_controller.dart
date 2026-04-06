import 'package:flutter/material.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/data/repositories/tournament_repository.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({TournamentRepository? tournamentRepository})
      : _tournamentRepository = tournamentRepository ?? FirestoreTournamentService();

  final TournamentRepository _tournamentRepository;

  Stream<List<AppTournament>> watchTournaments() {
    return _tournamentRepository.watchTournaments();
  }
}
