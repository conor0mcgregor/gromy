import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/features/local_tournament/data/models/local_athlete.dart';
import 'package:gromy/features/local_tournament/data/models/local_tournament.dart';
import 'package:gromy/features/local_tournament/data/repositories/local_tournament_repository.dart';
import 'package:gromy/features/local_tournament/presentation/controllers/local_tournament_controller.dart';
import 'package:gromy/features/local_tournament/presentation/screens/local_tournament_athletes_screen.dart';
import 'package:gromy/features/local_tournament/presentation/screens/local_tournaments_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRepo implements LocalTournamentRepository {
  final List<LocalTournament> list = [];
  @override
  Future<void> deleteTournament(String id) async => list.removeWhere((t) => t.id == id);
  @override
  Future<List<LocalTournament>> getAllTournaments() async => list;
  @override
  Future<LocalTournament?> getTournamentById(String id) async =>
      list.firstWhere((t) => t.id == id);
  @override
  Future<void> saveTournament(LocalTournament tournament) async {
    final idx = list.indexWhere((t) => t.id == tournament.id);
    if (idx != -1) {
      list[idx] = tournament;
    } else {
      list.add(tournament);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Registro rápido de atletas en LocalTournamentAthletesScreen', (tester) async {
    final repo = MockRepo();
    final tournament = LocalTournament(
      id: 'tourney_1',
      name: 'Torneo Rápido',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: LocalTournamentStatus.setup,
      athletes: const [],
      matches: const [],
    );

    final controller = LocalTournamentController(
      tournament: tournament,
      repository: repo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LocalTournamentAthletesScreen(controller: controller),
      ),
    );

    expect(find.text('Sin atletas inscritos'), findsOneWidget);

    // 1. Escribir nombre "Carlos" y pulsar "Añadir"
    await tester.enterText(find.byType(TextField).first, 'Carlos');
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();

    expect(find.text('Carlos'), findsOneWidget);
    expect(controller.athletes.length, 1);

    // 2. Escribir segundo atleta con el MISMO nombre ("Carlos") consecutivamente
    await tester.enterText(find.byType(TextField).first, 'Carlos');
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();

    // Deben aparecer 2 atletas en pantalla y en el controlador con IDs distintos
    expect(controller.athletes.length, 2);
    expect(controller.athletes[0].id, isNot(controller.athletes[1].id));
    expect(find.text('2 participantes'), findsOneWidget);
  });

  testWidgets('LocalTournamentsScreen muestra estado vacío y dialog de creación', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LocalTournamentsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sin torneos locales'), findsOneWidget);
    expect(find.text('Nuevo torneo'), findsOneWidget);

    // Pulsar botón flotante de nuevo torneo
    await tester.tap(find.text('Nuevo torneo'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo torneo local'), findsOneWidget);
    expect(find.text('Nombre del torneo'), findsOneWidget);
  });
}
