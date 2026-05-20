import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/core/models/registration_form.dart';
import 'package:gromy/database/participant/models/app_participant.dart';
import 'package:gromy/features/tournament/data/model/app_tournament.dart';
import 'package:gromy/features/tournament/data/model/enums_tournament.dart';
import 'package:gromy/features/tournament/data/repositories/tournament_repository.dart';
import 'package:gromy/features/tournament/domain/use_cases/create_tournament_use_case.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test(
    'published creation writes to tournament repository as published',
    () async {
      final repository = _FakeTournamentRepository();
      final useCase = CreateTournamentUseCase(repository);

      final tournament = await useCase(
        uid: 'owner-1',
        email: 'owner@example.com',
        displayName: 'Owner',
        name: 'Liga Primavera',
        description: 'Descripción suficiente',
        allInformation: 'Reglas completas del torneo para poder publicar.',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        maxParticipants: 8,
        location: 'Cancha Central',
        sport: TournamentSport.football,
        accessType: TournamentAccessType.publicOpen,
      );

      expect(repository.createCalls, 1);
      expect(repository.duplicateChecks, 0);
      expect(tournament.status, TournamentStatus.published);
      expect(tournament.isPubliclyVisible, isTrue);
      expect(tournament.acceptsRegistrations, isTrue);
    },
  );

  test('defensive draft tournament objects are not registration eligible', () {
    final tournament = _publishedTournament().copyWith(
      status: TournamentStatus.draft,
    );

    expect(tournament.isPubliclyVisible, isFalse);
    expect(tournament.acceptsRegistrations, isFalse);
  });

  test('legacy tournaments without status are treated as published', () {
    final tournament = AppTournament.fromMap({
      'id': 'legacy-id',
      'name': 'Legacy',
      'description': 'Existing public tournament',
      'allInformation': 'Rules',
      'scheduledAt': DateTime.now().add(const Duration(days: 1)),
      'maxParticipants': 8,
      'location': 'Cancha Central',
      'sport': 'football',
      'accessType': 'publicOpen',
      'organizerUid': 'owner-1',
      'adminIds': ['owner-1'],
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    });

    expect(tournament.status, TournamentStatus.published);
    expect(tournament.isPubliclyVisible, isTrue);
  });
}

AppTournament _publishedTournament() {
  final now = DateTime.now();
  return AppTournament(
    id: 'tournament-1',
    name: 'Liga Primavera',
    description: 'Descripción suficiente',
    allInformation: 'Reglas completas',
    scheduledAt: now.add(const Duration(days: 1)),
    maxParticipants: 8,
    location: 'Cancha Central',
    sport: TournamentSport.football,
    accessType: TournamentAccessType.publicOpen,
    organizerUid: 'owner-1',
    adminIds: const ['owner-1'],
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeTournamentRepository implements TournamentRepository {
  int createCalls = 0;
  int duplicateChecks = 0;

  @override
  Future<AppTournament> createTournament(AppTournament tournament) async {
    createCalls++;
    return tournament.copyWith(id: 'created-id');
  }

  @override
  Future<AppTournament> createTournamentWithCover({
    required AppTournament tournament,
    required XFile coverImage,
  }) async {
    createCalls++;
    return tournament.copyWith(id: 'created-id');
  }

  @override
  Future<AppTournament?> findDuplicateTournament({
    required DateTime scheduledAt,
    required String location,
  }) async {
    duplicateChecks++;
    return null;
  }

  @override
  Stream<List<AppTournament>> watchTournaments() {
    return Stream.value(const <AppTournament>[]);
  }

  @override
  Stream<List<AppTournament>> watchMyTournaments(String uid) {
    return Stream.value(const <AppTournament>[]);
  }

  @override
  Stream<List<AppTournament>> watchTournamentsAdmin(String uid) {
    return Stream.value(const <AppTournament>[]);
  }

  @override
  Future<AppTournament?> getTournament(String tournamentId) async => null;

  @override
  Stream<List<AppTournament>> watchHistoricalTournaments(String uid) {
    return Stream.value(const <AppTournament>[]);
  }

  @override
  Future<AppParticipant> joinTournament({
    required String tournamentId,
    required String entityId,
    required ParticipantEntityType entityType,
    ParticipantStatus status = ParticipantStatus.pending,
    String? categoryId,
    int registrationFormVersion = 0,
    List<RegistrationResponse> registrationResponses = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<AppParticipant>> getParticipants(String tournamentId) {
    throw UnimplementedError();
  }

  @override
  Stream<List<AppParticipant>> watchParticipants(String tournamentId) {
    throw UnimplementedError();
  }

  @override
  Stream<List<AppTournament>> watchEnrolledTournaments(String uid) {
    return Stream.value(const <AppTournament>[]);
  }

  @override
  Future<void> cancelInscription({
    required String tournamentId,
    required String participantId,
  }) async {}

  @override
  Future<void> incrementParticipantCount(String tournamentId) async {}

  @override
  Future<void> decrementParticipantCount(String tournamentId) async {}


}
