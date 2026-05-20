import 'package:flutter/material.dart';

import '../../data/models/app_match.dart';
import 'bracket_connector_painter.dart';
import 'bracket_layout_calculator.dart';
import 'draggable_match_card.dart';
import 'match_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BracketBoard  ·  Widget
//
//  Canvas 2D completo que renderiza el bracket como un plano navegable.
//  Dispone los rounds horizontalmente y los matches verticalmente,
//  con líneas de conexión entre ellos.
//
//  Se usa dentro de un InteractiveViewer con constrained: false
//  para permitir zoom y paneo libre.
//
//  En modo admin draft → usa DraggableMatchCard con drag & drop.
//  En otros modos → usa MatchCard estático (sin overhead de drag).
// ─────────────────────────────────────────────────────────────────────────────

class BracketBoard extends StatelessWidget {
  const BracketBoard({
    super.key,
    required this.matchesByRound,
    required this.totalRounds,
    required this.roundNameBuilder,
    this.isAdmin = false,
    this.isDraftMode = false,
    this.isDraggingAny = false,
    this.onMatchTap,
    this.onParticipantDropped,
    this.pendingSwapSourceMatchId,
    this.pendingSwapSourceSlot,
    this.onParticipantDoubleTap,
    this.matchCardWidth = 220,
  });

  /// Matches organizados por round (0-indexed).
  final Map<int, List<AppMatch>> matchesByRound;

  /// Número total de rounds.
  final int totalRounds;

  /// Función que devuelve el nombre del round.
  final String Function(int roundIndex) roundNameBuilder;

  /// Modo admin (permite edición).
  final bool isAdmin;

  /// True cuando el bracket está en borrador (habilita drag & drop).
  final bool isDraftMode;

  /// True cuando hay un drag activo (para atenuar otras cards).
  final bool isDraggingAny;

  /// Callback al tocar un match.
  final void Function(AppMatch match)? onMatchTap;

  /// Callback cuando un participante es soltado en un slot.
  final void Function(
    ParticipantDragData source,
    AppMatch targetMatch,
    int targetSlot,
  )? onParticipantDropped;

  final String? pendingSwapSourceMatchId;
  final int? pendingSwapSourceSlot;
  final void Function(AppMatch match, int slot)? onParticipantDoubleTap;

  final double matchCardWidth;

  static const _roundGap = 80.0;
  static const _headerHeight = 44.0;
  static const _paddingH = 40.0;
  static const _paddingV = 30.0;

  @override
  Widget build(BuildContext context) {
    if (matchesByRound.isEmpty) {
      return const SizedBox.shrink();
    }

    final layout = BracketLayoutCalculator(
      matchesByRound: matchesByRound,
      totalRounds: totalRounds,
      matchCardWidth: matchCardWidth,
      roundGap: _roundGap,
      headerHeight: _headerHeight,
      paddingH: _paddingH,
      paddingV: _paddingV,
    ).compute();

    final positions = layout.positions;
    final connections = _buildConnections();
    final completedConnections = _buildCompletedConnections();

    return SizedBox(
      width: layout.size.width,
      height: layout.size.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BracketConnectorPainter(
                matchPositions: positions,
                connections: connections,
                completedConnections: completedConnections,
              ),
            ),
          ),
          ..._buildRoundHeaders(),
          ..._buildMatchCards(positions),
        ],
      ),
    );
  }

  Map<String, String> _buildConnections() {
    final connections = <String, String>{};

    for (final matches in matchesByRound.values) {
      for (final match in matches) {
        if (match.childMatchId != null && match.childMatchId!.isNotEmpty) {
          connections[match.id] = match.childMatchId!;
        }
      }
    }

    return connections;
  }

  Set<String> _buildCompletedConnections() {
    final completed = <String>{};

    for (final matches in matchesByRound.values) {
      for (final match in matches) {
        if (match.winnerId != null && match.winnerId!.isNotEmpty) {
          completed.add(match.id);
        }
      }
    }

    return completed;
  }

  List<Widget> _buildRoundHeaders() {
    final headers = <Widget>[];

    for (int round = 0; round < totalRounds; round++) {
      final x = _paddingH + round * (matchCardWidth + _roundGap);

      headers.add(
        Positioned(
          left: x,
          top: _paddingV,
          child: SizedBox(
            width: matchCardWidth,
            height: _headerHeight,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  roundNameBuilder(round),
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return headers;
  }

  List<Widget> _buildMatchCards(Map<String, Rect> positions) {
    final cards = <Widget>[];

    for (int round = 0; round < totalRounds; round++) {
      final matches = matchesByRound[round] ?? [];
      if (matches.isEmpty) continue;

      final x = _paddingH + round * (matchCardWidth + _roundGap);

      for (final match in matches) {
        final rect = positions[match.id];
        if (rect == null) continue;

        final useDrag = isAdmin && isDraftMode && round == 0;

        cards.add(
          Positioned(
            left: x,
            top: rect.top,
            child: SizedBox(
              width: matchCardWidth,
              height: rect.height,
              child: useDrag
                  ? DraggableMatchCard(
                      key: ValueKey('dmc_${match.id}'),
                      match: match,
                      isDraftMode: isDraftMode,
                      isDraggingAny: isDraggingAny,
                      width: matchCardWidth,
                      onTap: () => onMatchTap?.call(match),
                      onDropped: (source, targetSlot) {
                        onParticipantDropped?.call(source, match, targetSlot);
                      },
                      pendingSwapSourceSlot:
                          pendingSwapSourceMatchId == match.id
                          ? pendingSwapSourceSlot
                          : null,
                      onParticipantDoubleTap: onParticipantDoubleTap != null
                          ? (slot) => onParticipantDoubleTap!(match, slot)
                          : null,
                    )
                  : MatchCard(
                      key: ValueKey('mc_${match.id}'),
                      match: match,
                      isAdmin: isAdmin,
                      width: matchCardWidth,
                      onTap: onMatchTap != null
                          ? () => onMatchTap!(match)
                          : null,
                    ),
            ),
          ),
        );
      }
    }

    return cards;
  }
}
