import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/features/tournament/data/model/enums_tournament.dart';
import 'package:gromy/features/tournament/data/repositories/tournament_repository.dart';
import 'package:gromy/features/tournament/domain/use_cases/create_tournament_use_case.dart';

void main() {
  test('new tournaments only accept Brazilian Jiu-Jitsu', () async {
    expect(TournamentSport.supportedForCreation, [
      TournamentSport.brazilianJiuJitsu,
    ]);
    expect(
      TournamentSport.fromValue('football'),
      TournamentSport.football,
      reason: 'Legacy Firestore tournaments remain readable.',
    );

    final useCase = CreateTournamentUseCase(_UnusedTournamentRepository());
    await expectLater(
      useCase.call(
        uid: 'organizer',
        email: null,
        displayName: null,
        name: 'Legacy sport',
        description: 'Tournament',
        allInformation: 'Details',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        maxParticipants: 8,
        location: 'Las Palmas',
        sport: TournamentSport.football,
        accessType: TournamentAccessType.publicOpen,
        maxMatchDurationMinutes: 5,
      ),
      throwsArgumentError,
    );
  });
}

class _UnusedTournamentRepository extends Fake
    implements TournamentRepository {}
