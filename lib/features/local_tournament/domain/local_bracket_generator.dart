import 'dart:math';

import '../data/models/local_athlete.dart';
import '../data/models/local_match.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalBracketGenerator  ·  Domain Service
//
//  Genera el bracket de eliminación directa (single-elimination) para un
//  torneo local a partir de una lista de atletas.
//
//  Características:
//    - Barajado aleatorio de participantes
//    - Byes automáticos para tornar el número de participantes a potencia de 2
//    - Árboles correctamente enlazados (parentMatchId / childMatchId)
//    - Sin dependencias externas ni de Firebase
// ─────────────────────────────────────────────────────────────────────────────

class LocalBracketGenerator {
  /// Genera los matches del bracket para los atletas dados.
  /// Los matches ya incluyen el enlace padre-hijo correcto.
  static ({List<LocalMatch> matches, int totalRounds}) generate({
    required String bracketId,
    required List<LocalAthlete> athletes,
    bool shuffle = true,
  }) {
    if (athletes.isEmpty) {
      return (matches: [], totalRounds: 0);
    }

    final shuffled = shuffle ? _shuffle(List.of(athletes)) : List.of(athletes);

    // Calcular potencia de 2 más cercana
    final slotCount = _nextPowerOfTwo(shuffled.length);
    final totalRounds = log2(slotCount);

    // Generar IDs únicos para todos los matches del bracket
    final allMatchIds = _generateMatchIds(bracketId, slotCount);

    final matches = <LocalMatch>[];

    // ── Construir el árbol de arriba hacia abajo ─────────────────────────────
    // Ronda 0 (primera ronda): slotCount / 2 matches
    // Ronda 1: slotCount / 4 matches
    // ...
    // Final: 1 match

    // Primero creamos los shells de todos los matches con sus IDs
    final matchShells = <String, _MatchShell>{};
    int offset = 0;
    for (int round = 0; round < totalRounds; round++) {
      final matchesInRound = slotCount ~/ (1 << (round + 1));
      for (int order = 0; order < matchesInRound; order++) {
        final id = allMatchIds[offset++];
        matchShells[id] = _MatchShell(id: id, round: round, matchOrder: order);
      }
    }

    // Enlazar padres e hijos
    _linkTree(matchShells, slotCount, allMatchIds, totalRounds);

    // Asignar atletas y byes a la primera ronda
    final round0Shells = matchShells.values.where((s) => s.round == 0).toList()
      ..sort((a, b) => a.matchOrder.compareTo(b.matchOrder));

    final numRound0Matches = slotCount ~/ 2;
    final numByes = slotCount - shuffled.length;
    final numFullMatches = numRound0Matches - numByes;

    // Distribuir atletas:
    // Los primeros `numFullMatches` tienen 2 atletas (a1 y a2)
    // Los siguientes `numByes` tienen 1 atleta y 1 BYE
    int athleteIdx = 0;
    for (int i = 0; i < round0Shells.length; i++) {
      final shell = round0Shells[i];
      LocalAthlete? a1;
      LocalAthlete? a2;
      LocalMatchStatus status;

      if (i < numFullMatches) {
        a1 = athleteIdx < shuffled.length ? shuffled[athleteIdx++] : null;
        a2 = athleteIdx < shuffled.length ? shuffled[athleteIdx++] : null;
        status = LocalMatchStatus.pending;
      } else {
        a1 = athleteIdx < shuffled.length ? shuffled[athleteIdx++] : null;
        a2 = null;
        status = LocalMatchStatus.bye;
      }

      matchShells[shell.id] = shell.copyWith(
        athlete1: a1,
        athlete2: a2,
        status: status,
      );
    }

    // Un BYE solo resuelve su propio match de primera ronda. El siguiente
    // enfrentamiento puede tener un rival que aún depende de otro match; por
    // tanto, no se debe convertir en BYE ni propagarlo de forma recursiva.
    _propagateByes(matchShells, totalRounds, bracketId);

    // Convertir a LocalMatch
    for (final shell in matchShells.values) {
      matches.add(_toLocalMatch(shell, bracketId));
    }

    return (matches: matches, totalRounds: totalRounds);
  }

  static void _propagateByes(
    Map<String, _MatchShell> shells,
    int totalRounds,
    String bracketId,
  ) {
    // Solo la primera ronda conoce de forma definitiva qué huecos no tienen
    // rival. En rondas posteriores un hueco vacío significa "pendiente del
    // match padre", no un BYE.
    final round0 = shells.values.where((s) => s.round == 0).toList()
      ..sort((a, b) => a.matchOrder.compareTo(b.matchOrder));

    for (final shell in round0) {
      if (shell.status == LocalMatchStatus.bye && shell.athlete1 != null) {
        // El atleta avanza automáticamente
        final winner = shell.athlete1!;
        shells[shell.id] = shell.copyWith(
          winnerId: winner.id,
          status: LocalMatchStatus.bye,
        );
        // Propagar al hijo
        _advanceToChild(shells, shell, winner);
      }
    }
  }

  static void _advanceToChild(
    Map<String, _MatchShell> shells,
    _MatchShell byeShell,
    LocalAthlete winner,
  ) {
    if (byeShell.childMatchId == null) return;
    final child = shells[byeShell.childMatchId!];
    if (child == null) return;

    if (byeShell.positionInChild == 1) {
      shells[child.id] = child.copyWith(athlete1: winner);
    } else if (byeShell.positionInChild == 2) {
      shells[child.id] = child.copyWith(athlete2: winner);
    }
  }

  static void _linkTree(
    Map<String, _MatchShell> shells,
    int slotCount,
    List<String> allMatchIds,
    int totalRounds,
  ) {
    // Para cada ronda > 0, los matches de ronda n son los hijos de ronda n-1
    // Match i de ronda n es hijo de matches 2i y 2i+1 de ronda n-1

    // Construir lista ordenada de IDs por ronda
    final byRound = <int, List<String>>{};
    for (final shell in shells.values) {
      byRound.putIfAbsent(shell.round, () => []).add(shell.id);
    }
    for (final list in byRound.values) {
      list.sort((a, b) {
        final sa = shells[a]!;
        final sb = shells[b]!;
        return sa.matchOrder.compareTo(sb.matchOrder);
      });
    }

    for (int round = 1; round < totalRounds; round++) {
      final parentRound = byRound[round - 1] ?? [];
      final currentRound = byRound[round] ?? [];

      for (int i = 0; i < currentRound.length; i++) {
        final childId = currentRound[i];
        final parent1Idx = i * 2;
        final parent2Idx = i * 2 + 1;

        if (parent1Idx < parentRound.length) {
          final p1Id = parentRound[parent1Idx];
          shells[p1Id] = shells[p1Id]!.copyWith(
            childMatchId: childId,
            positionInChild: 1,
          );
          final child = shells[childId]!;
          shells[childId] = child.copyWith(parentMatch1Id: p1Id);
        }
        if (parent2Idx < parentRound.length) {
          final p2Id = parentRound[parent2Idx];
          shells[p2Id] = shells[p2Id]!.copyWith(
            childMatchId: childId,
            positionInChild: 2,
          );
          final child = shells[childId]!;
          shells[childId] = child.copyWith(parentMatch2Id: p2Id);
        }
      }
    }
  }

  static LocalMatch _toLocalMatch(_MatchShell shell, String bracketId) {
    return LocalMatch(
      id: shell.id,
      bracketId: bracketId,
      round: shell.round,
      matchOrder: shell.matchOrder,
      status: shell.status,
      athlete1: shell.athlete1,
      athlete2: shell.athlete2,
      winnerId: shell.winnerId,
      parentMatch1Id: shell.parentMatch1Id,
      parentMatch2Id: shell.parentMatch2Id,
      childMatchId: shell.childMatchId,
      positionInChild: shell.positionInChild,
    );
  }

  static List<String> _generateMatchIds(String bracketId, int slotCount) {
    final ids = <String>[];
    int totalMatches = slotCount - 1; // Para elimináción directa: n-1 matches
    for (int i = 0; i < totalMatches; i++) {
      ids.add('${bracketId}_m${i.toString().padLeft(3, '0')}');
    }
    return ids;
  }

  static int _nextPowerOfTwo(int n) {
    if (n <= 1) return 1;
    int power = 1;
    while (power < n) {
      power <<= 1;
    }
    return power;
  }

  static int log2(int n) {
    int count = 0;
    while (n > 1) {
      n >>= 1;
      count++;
    }
    return count;
  }

  static List<LocalAthlete> _shuffle(List<LocalAthlete> list) {
    final rng = Random();
    for (int i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }
}

// ── Shell interno para el árbol de construcción ─────────────────────────────

class _MatchShell {
  final String id;
  final int round;
  final int matchOrder;
  final LocalMatchStatus status;
  final LocalAthlete? athlete1;
  final LocalAthlete? athlete2;
  final String? winnerId;
  final String? parentMatch1Id;
  final String? parentMatch2Id;
  final String? childMatchId;
  final int? positionInChild;

  const _MatchShell({
    required this.id,
    required this.round,
    required this.matchOrder,
    this.status = LocalMatchStatus.pending,
    this.athlete1,
    this.athlete2,
    this.winnerId,
    this.parentMatch1Id,
    this.parentMatch2Id,
    this.childMatchId,
    this.positionInChild,
  });

  _MatchShell copyWith({
    LocalMatchStatus? status,
    LocalAthlete? athlete1,
    LocalAthlete? athlete2,
    String? winnerId,
    String? parentMatch1Id,
    String? parentMatch2Id,
    String? childMatchId,
    int? positionInChild,
  }) {
    return _MatchShell(
      id: id,
      round: round,
      matchOrder: matchOrder,
      status: status ?? this.status,
      athlete1: athlete1 ?? this.athlete1,
      athlete2: athlete2 ?? this.athlete2,
      winnerId: winnerId ?? this.winnerId,
      parentMatch1Id: parentMatch1Id ?? this.parentMatch1Id,
      parentMatch2Id: parentMatch2Id ?? this.parentMatch2Id,
      childMatchId: childMatchId ?? this.childMatchId,
      positionInChild: positionInChild ?? this.positionInChild,
    );
  }
}
