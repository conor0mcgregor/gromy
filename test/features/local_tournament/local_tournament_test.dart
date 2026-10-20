import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/features/local_tournament/data/models/local_athlete.dart';
import 'package:gromy/features/local_tournament/data/models/local_match.dart';
import 'package:gromy/features/local_tournament/data/models/local_tournament.dart';
import 'package:gromy/features/local_tournament/data/repositories/local_tournament_repository.dart';
import 'package:gromy/features/local_tournament/domain/local_bracket_generator.dart';
import 'package:gromy/features/local_tournament/presentation/controllers/local_tournament_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// In-memory repository for unit testing
class MockLocalTournamentRepository implements LocalTournamentRepository {
  final Map<String, LocalTournament> _store = {};

  @override
  Future<List<LocalTournament>> getAllTournaments() async {
    final list = _store.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<LocalTournament?> getTournamentById(String id) async {
    return _store[id];
  }

  @override
  Future<void> saveTournament(LocalTournament tournament) async {
    _store[tournament.id] = tournament;
  }

  @override
  Future<void> deleteTournament(String id) async {
    _store.remove(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalAthlete Tests', () {
    test('Permite crear atleta únicamente con nombre y genera ID único', () {
      final a1 = LocalAthlete(id: 'uuid-1', name: 'Carlos');
      final a2 = LocalAthlete(id: 'uuid-2', name: 'Carlos');

      expect(a1.name, 'Carlos');
      expect(a2.name, 'Carlos');
      // Tienen el mismo nombre pero diferente ID -> son atletas distintos
      expect(a1 == a2, isFalse);
      expect(a1.id, isNot(a2.id));
    });

    test('Serialización y deserialización de LocalAthlete', () {
      final now = DateTime.now();
      final athlete = LocalAthlete(id: 'uuid-123', name: 'Lucía Fernández', createdAt: now);
      final map = athlete.toMap();
      final deserialized = LocalAthlete.fromMap(map);

      expect(deserialized.id, athlete.id);
      expect(deserialized.name, athlete.name);
      expect(deserialized == athlete, isTrue);
    });
  });

  group('LocalBracketGenerator Tests', () {
    test('Genera bracket de 2 atletas (1 ronda, 1 match)', () {
      final athletes = [
        const LocalAthlete(id: '1', name: 'Atleta 1'),
        const LocalAthlete(id: '2', name: 'Atleta 2'),
      ];

      final result = LocalBracketGenerator.generate(
        bracketId: 'test_b',
        athletes: athletes,
        shuffle: false,
      );

      expect(result.totalRounds, 1);
      expect(result.matches.length, 1);
      final match = result.matches.first;
      expect(match.round, 0);
      expect(match.athlete1?.name, 'Atleta 1');
      expect(match.athlete2?.name, 'Atleta 2');
      expect(match.status, LocalMatchStatus.pending);
      expect(match.isFinal, isTrue);
    });

    test('Genera bracket de 3 atletas con BYE automático hacia la final', () {
      final athletes = [
        const LocalAthlete(id: '1', name: 'Atleta 1'),
        const LocalAthlete(id: '2', name: 'Atleta 2'),
        const LocalAthlete(id: '3', name: 'Atleta 3'),
      ];

      final result = LocalBracketGenerator.generate(
        bracketId: 'test_b',
        athletes: athletes,
        shuffle: false,
      );

      expect(result.totalRounds, 2); // 4 slots -> 2 rondas
      expect(result.matches.length, 3); // 2 en ronda 0, 1 final

      final round0 = result.matches.where((m) => m.round == 0).toList();
      expect(round0.length, 2);

      // Match 0: Atleta 1 vs Atleta 2 (pending)
      expect(round0[0].status, LocalMatchStatus.pending);
      expect(round0[0].athlete1?.name, 'Atleta 1');
      expect(round0[0].athlete2?.name, 'Atleta 2');

      // Match 1: Atleta 3 vs BYE (automático)
      expect(round0[1].status, LocalMatchStatus.bye);
      expect(round0[1].athlete1?.name, 'Atleta 3');
      expect(round0[1].athlete2, isNull);
      expect(round0[1].winnerId, '3');

      // Final: el ganador de BYE (Atleta 3) ya avanzó automáticamente a la final!
      final finalMatch = result.matches.firstWhere((m) => m.round == 1);
      expect(finalMatch.athlete2?.name, 'Atleta 3');
    });

    test('Genera bracket de 4 atletas (2 rondas, 3 matches, 0 byes)', () {
      final athletes = [
        const LocalAthlete(id: '1', name: 'A'),
        const LocalAthlete(id: '2', name: 'B'),
        const LocalAthlete(id: '3', name: 'C'),
        const LocalAthlete(id: '4', name: 'D'),
      ];

      final result = LocalBracketGenerator.generate(
        bracketId: 'test_b',
        athletes: athletes,
        shuffle: false,
      );

      expect(result.totalRounds, 2);
      expect(result.matches.length, 3);

      final r0 = result.matches.where((m) => m.round == 0).toList();
      expect(r0.every((m) => m.status == LocalMatchStatus.pending), isTrue);
      expect(r0.every((m) => m.athlete1 != null && m.athlete2 != null), isTrue);
    });

    test('Genera bracket de 5 atletas (8 slots, 3 rondas, 3 byes, sin matches vacíos)', () {
      final athletes = [
        const LocalAthlete(id: '1', name: 'A1'),
        const LocalAthlete(id: '2', name: 'A2'),
        const LocalAthlete(id: '3', name: 'A3'),
        const LocalAthlete(id: '4', name: 'A4'),
        const LocalAthlete(id: '5', name: 'A5'),
      ];

      final result = LocalBracketGenerator.generate(
        bracketId: 'test_b',
        athletes: athletes,
        shuffle: false,
      );

      expect(result.totalRounds, 3);
      expect(result.matches.length, 7); // 4 + 2 + 1

      final r0 = result.matches.where((m) => m.round == 0).toList();
      expect(r0.length, 4);

      // Ningún match debe estar completamente vacío (a1 != null en todos)
      for (final m in r0) {
        expect(m.athlete1, isNotNull);
      }

      // Exactamente 3 byes
      final byes = r0.where((m) => m.isBye).toList();
      expect(byes.length, 3);

      // Los 3 byes avanzaron a semifinales
      final r1 = result.matches.where((m) => m.round == 1).toList();
      expect(r1.length, 2);
    });

    test('Genera bracket de 8 atletas (4 matches r0, 2 matches r1, 1 final)', () {
      final athletes = List.generate(
        8,
        (i) => LocalAthlete(id: '$i', name: 'Atleta $i'),
      );

      final result = LocalBracketGenerator.generate(
        bracketId: 'test_b',
        athletes: athletes,
        shuffle: false,
      );

      expect(result.totalRounds, 3);
      expect(result.matches.length, 7);
      expect(result.matches.where((m) => m.isBye).length, 0);
    });
  });

  group('LocalTournamentController Tests', () {
    late MockLocalTournamentRepository repository;
    late LocalTournamentController controller;

    setUp(() {
      repository = MockLocalTournamentRepository();
      final tournament = LocalTournament(
        id: 't_test',
        name: 'Torneo de Prueba',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: LocalTournamentStatus.setup,
        athletes: const [],
        matches: const [],
      );
      controller = LocalTournamentController(
        tournament: tournament,
        repository: repository,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Añadir atletas solo con nombre de forma consecutiva', () async {
      await controller.addAthlete('Marcos');
      await controller.addAthlete('Elena');
      await controller.addAthlete('Marcos'); // Nombre duplicado

      expect(controller.athletes.length, 3);
      expect(controller.athletes[0].name, 'Marcos');
      expect(controller.athletes[1].name, 'Elena');
      expect(controller.athletes[2].name, 'Marcos');

      // Tienen identificadores únicos a pesar del mismo nombre
      expect(controller.athletes[0].id, isNot(controller.athletes[2].id));

      // Verificación de persistencia
      final saved = await repository.getTournamentById('t_test');
      expect(saved?.athletes.length, 3);
    });

    test('Validación: no añade atletas con nombre vacío', () async {
      await controller.addAthlete('   ');
      await controller.addAthlete('');
      expect(controller.athletes.isEmpty, isTrue);
    });

    test('Editar y eliminar atleta', () async {
      await controller.addAthlete('Juan');
      final id = controller.athletes.first.id;

      await controller.editAthlete(id, 'Juan Carlos');
      expect(controller.athletes.first.name, 'Juan Carlos');

      await controller.removeAthlete(id);
      expect(controller.athletes.isEmpty, isTrue);
    });

    test('Añadir múltiples atletas en lote (bulk add)', () async {
      await controller.addAthletes(['Pablo', 'Sofía', 'Daniel', 'Paula']);
      expect(controller.athletes.length, 4);
    });

    test('Generar bracket, registrar ganador y avance automático', () async {
      await controller.addAthletes(['A1', 'A2', 'A3', 'A4']);
      await controller.generateBracket();

      expect(controller.hasBracket, isTrue);
      expect(controller.totalRounds, 2);

      final r0 = controller.matches.where((m) => m.round == 0).toList();
      final match0 = r0.first;

      // Registrar victoria de atleta 1 en match 0
      final winnerId = match0.athlete1!.id;
      final loserId = match0.athlete2!.id;

      final error = await controller.recordMatchResult(
        matchId: match0.id,
        winnerId: winnerId,
        loserId: loserId,
        scoreAthlete1: 10,
        scoreAthlete2: 7,
      );

      expect(error, isNull);

      // El ganador avanzó automáticamente a la final (round 1)
      final finalMatch = controller.matches.firstWhere((m) => m.round == 1);
      expect(finalMatch.athlete1?.id, winnerId);
      expect(finalMatch.athlete1?.name, match0.athlete1?.name);
    });

    test('Intercambiar participantes en primera ronda', () async {
      await controller.addAthletes(['A1', 'A2', 'A3', 'A4']);
      await controller.generateBracket();

      final r0 = controller.matches.where((m) => m.round == 0).toList();
      final m1 = r0[0];
      final m2 = r0[1];

      final originalA1 = m1.athlete1?.name;
      final originalA3 = m2.athlete1?.name;

      // Intercambiar slot 1 de match 1 con slot 1 de match 2
      final error = await controller.swapAthletes(
        matchId1: m1.id,
        slot1: 1,
        matchId2: m2.id,
        slot2: 1,
      );

      expect(error, isNull);

      final updatedM1 = controller.matches.firstWhere((m) => m.id == m1.id);
      final updatedM2 = controller.matches.firstWhere((m) => m.id == m2.id);

      expect(updatedM1.athlete1?.name, originalA3);
      expect(updatedM2.athlete1?.name, originalA1);
    });

    test('Gestión de errores: deshacer resultado limpia recursivamente al ganador', () async {
      await controller.addAthletes(['A1', 'A2', 'A3', 'A4']);
      await controller.generateBracket();

      final r0 = controller.matches.where((m) => m.round == 0).toList();
      final match0 = r0.first;
      final winnerId = match0.athlete1!.id;

      // 1. Ganar semifinal
      await controller.recordMatchResult(
        matchId: match0.id,
        winnerId: winnerId,
        loserId: match0.athlete2!.id,
      );

      // Ver que avanzó a la final
      var finalMatch = controller.matches.firstWhere((m) => m.round == 1);
      expect(finalMatch.athlete1?.id, winnerId);

      // 2. Deshacer el resultado de match0
      await controller.undoMatchResult(match0.id);

      // El match volvió a pending
      final resetMatch0 = controller.matches.firstWhere((m) => m.id == match0.id);
      expect(resetMatch0.status, LocalMatchStatus.pending);
      expect(resetMatch0.winnerId, isNull);

      // El participante fue limpiado de la final
      finalMatch = controller.matches.firstWhere((m) => m.round == 1);
      expect(finalMatch.athlete1, isNull);
    });

    test('Modificar resultado previo actualiza la siguiente ronda sin inconsistencias', () async {
      await controller.addAthletes(['A1', 'A2', 'A3', 'A4']);
      await controller.generateBracket();

      final r0 = controller.matches.where((m) => m.round == 0).toList();
      final match0 = r0.first;
      final a1Id = match0.athlete1!.id;
      final a2Id = match0.athlete2!.id;

      // 1. Gana A1 inicialmente
      await controller.recordMatchResult(
        matchId: match0.id,
        winnerId: a1Id,
        loserId: a2Id,
      );

      var finalMatch = controller.matches.firstWhere((m) => m.round == 1);
      expect(finalMatch.athlete1?.id, a1Id);

      // 2. Se corrige el resultado: en realidad ganó A2
      await controller.recordMatchResult(
        matchId: match0.id,
        winnerId: a2Id,
        loserId: a1Id,
      );

      final updatedMatch0 = controller.matches.firstWhere((m) => m.id == match0.id);
      expect(updatedMatch0.winnerId, a2Id);

      // En la final ahora está A2, NO A1
      finalMatch = controller.matches.firstWhere((m) => m.round == 1);
      expect(finalMatch.athlete1?.id, a2Id);
      expect(finalMatch.athlete1?.name, match0.athlete2?.name);
    });
  });
}
