import 'dart:ui';

import '../../data/models/app_match.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BracketLayoutCalculator  ·  Posicionamiento dinámico del bracket
//
//  Calcula alturas por enfrentamiento según su contenido (horario, nombres…)
//  y posiciona cada card sin solapamientos. Los conectores usan el centro
//  real de cada Rect.
// ─────────────────────────────────────────────────────────────────────────────

class BracketLayout {
  const BracketLayout({required this.positions, required this.size});

  final Map<String, Rect> positions;
  final Size size;
}

class BracketLayoutCalculator {
  BracketLayoutCalculator({
    required this.matchesByRound,
    required this.totalRounds,
    this.matchCardWidth = 220,
    this.roundGap = 80,
    this.round0Gap = 24,
    this.headerHeight = 44,
    this.paddingH = 40,
    this.paddingV = 30,
  });

  final Map<int, List<AppMatch>> matchesByRound;
  final int totalRounds;
  final double matchCardWidth;
  final double roundGap;
  final double round0Gap;
  final double headerHeight;
  final double paddingH;
  final double paddingV;

  static const double _headerBlock = 30;
  static const double _separator = 1;
  static const double _footerBlock = 28;
  static const double _rowCompact = 42;
  static const double _rowExpanded = 54;
  static const double _minCardHeight = 108;

  /// Altura estimada de la tarjeta según el contenido del match.
  static double estimateMatchCardHeight(AppMatch match) {
    final row1 = _participantRowHeight(match.participant1Name);
    final row2 = _participantRowHeight(match.participant2Name);
    var height = _headerBlock + row1 + _separator + row2;
    if (match.scheduledAt != null) {
      height += _footerBlock;
    }
    return height < _minCardHeight ? _minCardHeight : height;
  }

  static double _participantRowHeight(String? name) {
    final length = name?.trim().length ?? 0;
    return length > 22 ? _rowExpanded : _rowCompact;
  }

  BracketLayout compute() {
    final positions = <String, Rect>{};
    final heights = <String, double>{};

    for (final matches in matchesByRound.values) {
      for (final match in matches) {
        heights[match.id] = estimateMatchCardHeight(match);
      }
    }

    // Primera ronda: apilado vertical con separación fija.
    final round0 = matchesByRound[0] ?? [];
    final x0 = paddingH;
    var y = paddingV + headerHeight;
    for (var i = 0; i < round0.length; i++) {
      final match = round0[i];
      final h = heights[match.id]!;
      positions[match.id] = Rect.fromLTWH(x0, y, matchCardWidth, h);
      if (i < round0.length - 1) {
        y += h + round0Gap;
      } else {
        y += h;
      }
    }

    // Rondas siguientes: centrar entre padres cuando existan.
    for (var round = 1; round < totalRounds; round++) {
      final matches = matchesByRound[round] ?? [];
      if (matches.isEmpty) continue;

      final x = paddingH + round * (matchCardWidth + roundGap);

      for (var i = 0; i < matches.length; i++) {
        final match = matches[i];
        final h = heights[match.id]!;
        final centerY = _resolveCenterY(
          match: match,
          index: i,
          roundMatches: matches,
          positions: positions,
          heights: heights,
        );
        final top = centerY - h / 2;
        positions[match.id] = Rect.fromLTWH(x, top, matchCardWidth, h);
      }
    }

    final totalWidth =
        paddingH * 2 +
        totalRounds * matchCardWidth +
        (totalRounds - 1) * roundGap;

    var maxBottom = paddingV + headerHeight;
    for (final rect in positions.values) {
      if (rect.bottom > maxBottom) maxBottom = rect.bottom;
    }
    final totalHeight = maxBottom + paddingV;

    return BracketLayout(
      positions: positions,
      size: Size(totalWidth, totalHeight.clamp(400, double.infinity)),
    );
  }

  double _resolveCenterY({
    required AppMatch match,
    required int index,
    required List<AppMatch> roundMatches,
    required Map<String, Rect> positions,
    required Map<String, double> heights,
  }) {
    final p1 = match.parentMatch1Id;
    final p2 = match.parentMatch2Id;
    final r1 = p1 != null ? positions[p1] : null;
    final r2 = p2 != null ? positions[p2] : null;

    if (r1 != null && r2 != null) {
      return (r1.center.dy + r2.center.dy) / 2;
    }
    if (r1 != null) return r1.center.dy;
    if (r2 != null) return r2.center.dy;

    // Fallback: reparto proporcional del bloque de la primera ronda.
    final round0 = matchesByRound[0] ?? [];
    var firstRoundSpan = 0.0;
    for (var i = 0; i < round0.length; i++) {
      final h = heights[round0[i].id]!;
      firstRoundSpan += h;
      if (i < round0.length - 1) firstRoundSpan += round0Gap;
    }

    final sectionHeight = firstRoundSpan / roundMatches.length;
    return paddingV +
        headerHeight +
        index * sectionHeight +
        sectionHeight / 2;
  }
}
