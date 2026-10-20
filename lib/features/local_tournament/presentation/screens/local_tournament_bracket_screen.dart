import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../brackets/data/models/app_match.dart';
import '../../../brackets/presentation/controllers/bracket_admin_controller.dart' show DragSlotData;
import '../../../brackets/presentation/widgets/bracket_board.dart';
import '../../../brackets/presentation/widgets/bracket_swap_confirmation_dialog.dart';
import '../../../brackets/presentation/widgets/draggable_match_card.dart';
import '../../data/models/local_tournament.dart';
import '../controllers/local_tournament_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalTournamentBracketScreen  ·  Presentation
//
//  Rediseño integral del bracket de torneos locales.
//  Reutiliza BracketBoard, DraggableMatchCard, MatchCard, BracketConnectorPainter
//  y BracketLayoutCalculator para garantizar 100% de coherencia visual y funcional
//  con los brackets online de Gromy, sin duplicar código.
//
//  Funcionalidades:
//    - Zoom y desplazamiento 2D (InteractiveViewer, escala 0.2 a 2.5, botón reset).
//    - Intercambio por Drag & Drop en primera ronda.
//    - Intercambio por doble toque / menú con diálogo de confirmación.
//    - Registro rápido de resultado y puntuación con avance automático.
//    - Opción de corregir o deshacer resultado con limpieza recursiva de descendientes.
// ─────────────────────────────────────────────────────────────────────────────

class LocalTournamentBracketScreen extends StatefulWidget {
  const LocalTournamentBracketScreen({
    super.key,
    required this.controller,
  });

  final LocalTournamentController controller;

  @override
  State<LocalTournamentBracketScreen> createState() =>
      _LocalTournamentBracketScreenState();
}

class _LocalTournamentBracketScreenState
    extends State<LocalTournamentBracketScreen> {
  final _transformationController = TransformationController();

  LocalTournamentController get _controller => widget.controller;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        _showControllerMessages();

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(),
          body: _buildBody(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(Icons.arrow_back_rounded,
              size: 18, color: Colors.white.withValues(alpha: 0.8)),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(
            _controller.current.name,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Bracket del torneo',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        // Botón de reset zoom
        IconButton(
          tooltip: 'Restablecer zoom',
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.center_focus_strong_rounded,
                size: 16, color: Colors.white.withValues(alpha: 0.7)),
          ),
          onPressed: () => _transformationController.value = Matrix4.identity(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (!_controller.hasBracket) {
      return _buildNoBracketView();
    }

    final pendingSwap = _controller.pendingSwapSource;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),

        // Badge de estado del torneo
        _buildTournamentStatusBadge(),

        // Banner informativo de arrastre
        _buildDragHint(),

        // Canvas 2D con zoom y paneo
        Expanded(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(240),
                minScale: 0.2,
                maxScale: 2.5,
                child: BracketBoard(
                  matchesByRound: _controller.appMatchesByRound,
                  totalRounds: _controller.totalRounds,
                  roundNameBuilder: _controller.roundName,
                  isAdmin: true,
                  isDraftMode: true,
                  isDraggingAny: false,
                  onMatchTap: _onMatchTap,
                  onParticipantDropped: _onParticipantDropped,
                  pendingSwapSourceMatchId: pendingSwap?.match.id,
                  pendingSwapSourceSlot: pendingSwap?.slot,
                  onParticipantDoubleTap: _onParticipantDoubleTap,
                ),
              ),

              // Banner de intercambio manual activo
              if (pendingSwap != null)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: _buildPendingSwapBanner(pendingSwap),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentStatusBadge() {
    final status = _controller.current.status;
    final (color, label) = switch (status) {
      LocalTournamentStatus.setup => (const Color(0xFF6C63FF), 'CONFIGURANDO'),
      LocalTournamentStatus.inProgress => (const Color(0xFFF59E0B), 'EN CURSO'),
      LocalTournamentStatus.finished => (const Color(0xFF22C55E), 'FINALIZADO'),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHint() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_rounded,
              size: 14, color: Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Toca un match para registrar resultado. Arrastra en ronda 1 para intercambiar.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSwapBanner(DragSlotData pending) {
    final name = pending.participantName ?? 'Participante';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded,
              color: Color(0xFF22C55E), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Modo intercambio activo',
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toca dos veces a otro participante para intercambiarlo con "$name".',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _controller.cancelManualSwap(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBracketView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.account_tree_rounded,
                  size: 40, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin bracket generado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Genera el cuadro de emparejamientos a partir de los atletas inscritos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _controller.generateBracket(),
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: const Text('Generar bracket',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Drag & Drop & Swap Handler ───────────────────────────────────────────

  void _onParticipantDropped(
    ParticipantDragData source,
    AppMatch targetMatch,
    int targetSlot,
  ) async {
    await _confirmAndExecuteSwap(
      sourceMatch: source.match,
      sourceSlot: source.slot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
    );
  }

  void _onParticipantDoubleTap(AppMatch targetMatch, int targetSlot) async {
    final pending = _controller.pendingSwapSource;
    if (pending == null) return;

    await _confirmAndExecuteSwap(
      sourceMatch: pending.match,
      sourceSlot: pending.slot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
      clearManualSwapOnSuccess: true,
    );
  }

  Future<void> _confirmAndExecuteSwap({
    required AppMatch sourceMatch,
    required int sourceSlot,
    required AppMatch targetMatch,
    required int targetSlot,
    bool clearManualSwapOnSuccess = false,
  }) async {
    final previewError = _controller.validateSwapPreview(
      sourceMatch: sourceMatch,
      sourceSlot: sourceSlot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
    );
    if (previewError != null) {
      _showResultSnackBar(previewError, isError: true);
      return;
    }

    final confirmed = await showBracketSwapConfirmationDialog(
      context: context,
      sourceMatch: sourceMatch,
      sourceSlot: sourceSlot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
      roundNameBuilder: _controller.roundName,
    );
    if (!confirmed || !mounted) return;

    final errorMsg = await _controller.swapParticipantsDragDrop(
      sourceMatch: sourceMatch,
      sourceSlot: sourceSlot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
    );

    if (!mounted) return;

    if (errorMsg == null && clearManualSwapOnSuccess) {
      _controller.cancelManualSwap();
    }

    if (errorMsg != null) {
      _showResultSnackBar(errorMsg, isError: true);
    } else {
      _showResultSnackBar('Participantes intercambiados correctamente');
    }
  }

  // ── Match Tap & Actions ──────────────────────────────────────────────────

  void _onMatchTap(AppMatch match) async {
    if (match.isBye) {
      _showResultSnackBar('Este enfrentamiento es un BYE automático.');
      return;
    }

    final action = await _showMatchActionSheet(match);
    if (!mounted || action == null) return;

    switch (action) {
      case 'result':
        await _showRecordResultDialog(match);
      case 'undo':
        await _controller.undoMatchResult(match.id);
      case 'swap':
        _pickSwapSlot(match);
    }
  }

  Future<String?> _showMatchActionSheet(AppMatch match) {
    final canRecord = match.isReady && !match.isBye;
    final canUndo = match.isCompleted;
    final canSwap = match.round == 0 && !match.isCompleted;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Text(
                  _controller.roundName(match.round),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (canRecord)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: Color(0xFF22C55E), size: 20),
                    ),
                    title: const Text(
                      'Registrar resultado',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      match.isCompleted
                          ? 'Modificar el resultado actual'
                          : 'Anotar ganador y puntuación',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(ctx, 'result'),
                  ),
                if (canSwap)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.swap_horiz_rounded,
                          color: Color(0xFF6C63FF), size: 20),
                    ),
                    title: const Text(
                      'Intercambiar participante',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Mover de posición en primera ronda',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(ctx, 'swap'),
                  ),
                if (canUndo)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.undo_rounded,
                          color: Color(0xFFEF4444), size: 20),
                    ),
                    title: const Text(
                      'Deshacer resultado',
                      style: TextStyle(
                          color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Restablece el match a pendiente',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(ctx, 'undo'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickSwapSlot(AppMatch match) async {
    final slot = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona el participante a mover',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (match.participant1Name != null)
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  tileColor: Colors.white.withValues(alpha: 0.05),
                  leading: const Icon(Icons.person_rounded,
                      color: Color(0xFF6C63FF)),
                  title: Text(match.participant1Name!,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(ctx, 1),
                ),
              const SizedBox(height: 8),
              if (match.participant2Name != null)
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  tileColor: Colors.white.withValues(alpha: 0.05),
                  leading: const Icon(Icons.person_rounded,
                      color: Color(0xFF6C63FF)),
                  title: Text(match.participant2Name!,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(ctx, 2),
                ),
            ],
          ),
        ),
      ),
    );

    if (slot != null && mounted) {
      _controller.startManualSwap(match, slot);
    }
  }

  // ── Diálogo de Registro de Resultado Local ────────────────────────────────

  Future<void> _showRecordResultDialog(AppMatch match) async {
    final p1Name = match.participant1Name ?? 'Participante 1';
    final p2Name = match.participant2Name ?? 'Participante 2';

    final score1Ctrl =
        TextEditingController(text: '${match.scoreParticipant1 ?? 0}');
    final score2Ctrl =
        TextEditingController(text: '${match.scoreParticipant2 ?? 0}');

    String? selectedWinnerId = match.winnerId;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 380,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.emoji_events_rounded,
                                color: Color(0xFF6C63FF), size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registrar resultado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Toca al ganador y anota las puntuaciones',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Participante 1
                      _buildLocalParticipantPickerCard(
                        name: p1Name,
                        isSelected: selectedWinnerId == match.participant1Id,
                        scoreController: score1Ctrl,
                        onTap: () {
                          setDialogState(() {
                            selectedWinnerId = match.participant1Id;
                          });
                        },
                      ),

                      // Separador VS
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Participante 2
                      _buildLocalParticipantPickerCard(
                        name: p2Name,
                        isSelected: selectedWinnerId == match.participant2Id,
                        scoreController: score2Ctrl,
                        onTap: () {
                          setDialogState(() {
                            selectedWinnerId = match.participant2Id;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selectedWinnerId != null
                                  ? () => Navigator.pop(ctx, true)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFF22C55E).withValues(alpha: 0.3),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Confirmar',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result == true && selectedWinnerId != null && mounted) {
      final s1 = int.tryParse(score1Ctrl.text.trim()) ?? 0;
      final s2 = int.tryParse(score2Ctrl.text.trim()) ?? 0;
      final loserId = selectedWinnerId == match.participant1Id
          ? match.participant2Id!
          : match.participant1Id!;

      await _controller.recordMatchResult(
        matchId: match.id,
        winnerId: selectedWinnerId!,
        loserId: loserId,
        scoreAthlete1: s1,
        scoreAthlete2: s2,
      );
    }
  }

  Widget _buildLocalParticipantPickerCard({
    required String name,
    required bool isSelected,
    required TextEditingController scoreController,
    required VoidCallback onTap,
  }) {
    const accent = Color(0xFF22C55E);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected
              ? accent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Avatar con inicial
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? accent.withValues(alpha: 0.25)
                    : const Color(0xFF6C63FF).withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isSelected ? accent : const Color(0xFF6C63FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isSelected)
                    const Text(
                      'Ganador seleccionado',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Input de puntuación
            Container(
              width: 52,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? accent.withValues(alpha: 0.15)
                    : const Color(0xFF1E293B),
                border: Border.all(
                  color: isSelected
                      ? accent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: TextField(
                  controller: scoreController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isSelected ? accent : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notificaciones ───────────────────────────────────────────────────────

  void _showResultSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showControllerMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.successMessage != null) {
        _showResultSnackBar(_controller.successMessage!);
        _controller.clearMessages();
      }
      if (_controller.errorMessage != null) {
        _showResultSnackBar(_controller.errorMessage!, isError: true);
        _controller.clearMessages();
      }
    });
  }
}
