import '../model/app_tournament.dart';

abstract interface class TournamentRepository {
  Future<AppTournament> createTournament(AppTournament tournament);
}
