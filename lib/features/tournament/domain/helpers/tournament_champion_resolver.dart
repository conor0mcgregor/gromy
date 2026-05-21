import '../../../brackets/data/models/app_bracket.dart';
import '../../../brackets/data/models/app_match.dart';
import '../../../brackets/data/models/bracket_enums.dart';
import '../../../brackets/data/repositories/bracket_repository.dart';
import '../../../brackets/data/services/firestore_bracket_service.dart';

/// Resumen histórico de un torneo completado (ganador, formato, fecha fin).
class OldTournamentSummary {
  const OldTournamentSummary({
    this.championName,
    this.formatLabel,
    this.formatShortLabel,
    this.completedAt,
  });

  final String? championName;
  final String? formatLabel;
  final String? formatShortLabel;
  final DateTime? completedAt;
}

/// Obtiene ganador y formato desde los brackets del torneo.
class TournamentChampionResolver {
  TournamentChampionResolver({BracketRepository? repository})
      : _repository = repository ?? FirestoreBracketService();

  final BracketRepository _repository;

  Future<OldTournamentSummary> resolve(String tournamentId) async {
    final brackets = await _repository.watchBrackets(tournamentId).first;
    if (brackets.isEmpty) {
      return const OldTournamentSummary();
    }

    final bracket = brackets.firstWhere(
      (b) => b.status == BracketStatus.completed,
      orElse: () => brackets.first,
    );

    final championName = await _resolveChampionName(bracket);
    return OldTournamentSummary(
      championName: championName,
      formatLabel: bracket.format.label,
      formatShortLabel: _shortFormatLabel(bracket.format),
      completedAt: bracket.completedAt,
    );
  }

  Future<String?> _resolveChampionName(AppBracket bracket) async {
    final matches = await _repository.getMatches(bracket.id);
    if (matches.isEmpty) return null;

    final finalRound = bracket.totalRounds > 0 ? bracket.totalRounds - 1 : 0;
    final finalMatches = matches
        .where((m) => m.round == finalRound && m.winnerId != null)
        .toList();

    AppMatch? finalMatch;
    if (finalMatches.isNotEmpty) {
      finalMatches.sort((a, b) => b.matchOrder.compareTo(a.matchOrder));
      finalMatch = finalMatches.first;
    } else {
      final completed = matches
          .where((m) => m.winnerId != null && m.winnerId!.isNotEmpty)
          .toList();
      if (completed.isEmpty) return null;
      completed.sort((a, b) {
        final roundCmp = b.round.compareTo(a.round);
        if (roundCmp != 0) return roundCmp;
        return b.matchOrder.compareTo(a.matchOrder);
      });
      finalMatch = completed.first;
    }

    return _winnerDisplayName(finalMatch);
  }

  String? _winnerDisplayName(AppMatch match) {
    final winnerId = match.winnerId;
    if (winnerId == null || winnerId.isEmpty) return null;

    if (winnerId == match.participant1Id) {
      return match.participant1Name;
    }
    if (winnerId == match.participant2Id) {
      return match.participant2Name;
    }
    return null;
  }

  String _shortFormatLabel(BracketFormat format) => switch (format) {
        BracketFormat.singleElimination => 'KO',
        BracketFormat.doubleElimination => 'Doble KO',
        BracketFormat.roundRobin => 'Liga',
        BracketFormat.swiss => 'Suizo',
      };
}
