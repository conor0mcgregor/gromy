import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/models/app_match.dart';
import '../controllers/bracket_controller.dart';
import '../controllers/bracket_admin_controller.dart';
import '../widgets/bracket_board.dart';
import '../widgets/bracket_swap_confirmation_dialog.dart';
import '../widgets/category_selector.dart';
import '../widgets/draggable_match_card.dart';
import '../widgets/match_detail_panel.dart';
import '../widgets/match_result_dialog.dart';

class BracketScreen extends StatefulWidget {
  const BracketScreen({
    super.key,
    required this.tournamentId,
    this.isAdmin = false,
  });

  final String tournamentId;
  final bool isAdmin;

  @override
  State<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends State<BracketScreen> {
  late final BracketController _controller;
  BracketAdminController? _adminController;
  final _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _controller = BracketController(tournamentId: widget.tournamentId);
    if (widget.isAdmin) {
      _adminController = BracketAdminController(tournamentId: widget.tournamentId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _adminController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: widget.isAdmin ? _buildAdminBody() : _buildPublicBody(),
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
          child: Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white.withValues(alpha: 0.8)),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Enfrentamientos',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 17, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
      actions: [
        // Botón de reset zoom
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.center_focus_strong_rounded, size: 16, color: Colors.white.withValues(alpha: 0.6)),
          ),
          onPressed: () => _transformationController.value = Matrix4.identity(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Public body ────────────────────────────────────────────────────────

  Widget _buildPublicBody() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return switch (_controller.state) {
          BracketViewState.loading => _buildLoading(),
          BracketViewState.empty => _buildEmpty(),
          BracketViewState.error => _buildError(_controller.errorMessage),
          BracketViewState.loaded => _buildBracketView(
            matchesByRound: _controller.matchesByRound,
            totalRounds: _controller.selectedBracket?.totalRounds ?? 0,
            roundNameBuilder: (i) => _controller.roundName(i, _controller.selectedBracket?.totalRounds ?? 0),
            categories: _controller.availableCategories,
            selectedCategory: _controller.selectedBracket?.categoryName,
            onCategorySelected: _controller.selectCategory,
            isAdmin: false,
          ),
        };
      },
    );
  }

  // ── Admin body ─────────────────────────────────────────────────────────

  Widget _buildAdminBody() {
    return ListenableBuilder(
      listenable: _adminController!,
      builder: (context, _) {
        _showAdminMessages();

        if (!_adminController!.hasBracket) return _buildNoBracketAdmin();

        final admin = _adminController!;
        final isLoading = admin.state == BracketAdminState.loading || admin.state == BracketAdminState.generating;
        if (isLoading && admin.matches.isEmpty) return _buildLoading();

        return _buildBracketView(
          matchesByRound: admin.matchesByRound,
          totalRounds: admin.activeBracket?.totalRounds ?? 0,
          roundNameBuilder: admin.roundName,
          categories: admin.brackets
              .where((b) => b.categoryName != null && b.categoryName!.isNotEmpty)
              .map((b) => b.categoryName!)
              .toSet()
              .toList(),
          selectedCategory: admin.activeBracket?.categoryName,
          onCategorySelected: (cat) {
            final bracket = admin.brackets.firstWhere((b) => b.categoryName == cat);
            admin.selectBracket(bracket);
          },
          isAdmin: true,
        );
      },
    );
  }

  // ── Shared bracket view ────────────────────────────────────────────────

  Widget _buildBracketView({
    required Map<int, List<AppMatch>> matchesByRound,
    required int totalRounds,
    required String Function(int) roundNameBuilder,
    required List<String> categories,
    required String? selectedCategory,
    required void Function(String) onCategorySelected,
    required bool isAdmin,
  }) {
    final admin = _adminController;
    final isDraft = admin?.isDraftMode ?? false;
    final isDragging = admin?.isDragging ?? false;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
        if (isAdmin && admin?.activeBracket != null) _buildStatusBadge(),
        // Drag hint only in draft mode
        if (isAdmin && isDraft) _buildDragHint(),
        if (isAdmin && isDraft) _buildAdminButtonsSection(),
        CategorySelector(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
        ),
        if (categories.length > 1) const SizedBox(height: 12),
        Expanded(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.2,
                maxScale: 2.5,
                child: BracketBoard(
                  matchesByRound: matchesByRound,
                  totalRounds: totalRounds,
                  roundNameBuilder: roundNameBuilder,
                  isAdmin: isAdmin,
                  isDraftMode: isDraft,
                  isDraggingAny: isDragging,
                  onMatchTap: isAdmin ? _onMatchTapAdmin : _showMatchDetails,
                  onParticipantDropped: isAdmin ? _onParticipantDropped : null,
                  pendingSwapSourceMatchId: admin?.pendingSwapSource?.match.id,
                  pendingSwapSourceSlot: admin?.pendingSwapSource?.slot,
                  onParticipantDoubleTap: isAdmin ? _onParticipantDoubleTap : null,
                ),
              ),
              if (admin?.state == BracketAdminState.saving)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ),
              if (admin?.pendingSwapSource != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildPendingSwapBanner(admin!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Pending Swap Banner ──────────────────────────────────────────────────

  Widget _buildPendingSwapBanner(BracketAdminController admin) {
    final sourceName = admin.pendingSwapSource!.participantName ?? 'Participante';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_rounded, color: Color(0xFF22C55E), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Modo intercambio', style: TextStyle(color: Color(0xFF22C55E), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text('Doble toque sobre otro participante para intercambiarlo con $sourceName', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w500, height: 1.2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => admin.cancelManualSwap(),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1)),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Drag hint banner ────────────────────────────────────────────────────

  Widget _buildDragHint() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.drag_indicator_rounded, size: 15, color: Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Arrastra un participante a otro slot y confirma el intercambio',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drag & drop handler ────────────────────────────────────────────────

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
    final admin = _adminController;
    if (admin == null || admin.pendingSwapSource == null) return;

    final source = admin.pendingSwapSource!;
    await _confirmAndExecuteSwap(
      sourceMatch: source.match,
      sourceSlot: source.slot,
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
    final admin = _adminController;
    if (admin == null || admin.state == BracketAdminState.saving) return;

    final previewError = admin.validateSwapPreview(
      sourceMatch: sourceMatch,
      sourceSlot: sourceSlot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
    );
    if (previewError != null) {
      _showSwapResultSnackBar(previewError);
      return;
    }

    final roundNameBuilder = admin.roundName;
    final confirmed = await showBracketSwapConfirmationDialog(
      context: context,
      sourceMatch: sourceMatch,
      sourceSlot: sourceSlot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
      roundNameBuilder: roundNameBuilder,
    );
    if (!confirmed || !mounted) return;

    final errorMsg = await admin.swapParticipantsDragDrop(
      sourceMatch: sourceMatch,
      sourceSlot: sourceSlot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
    );

    if (!mounted) return;

    if (errorMsg == null && clearManualSwapOnSuccess) {
      admin.cancelManualSwap();
    }
    _showSwapResultSnackBar(errorMsg);
  }

  void _showSwapResultSnackBar(String? errorMsg) {
    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Participantes intercambiados'),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Admin match tap ────────────────────────────────────────────────────

  void _onMatchTapAdmin(AppMatch match) async {
    final action = await _showMatchAdminSheet(match);
    if (!mounted || action == null) return;

    switch (action) {
      case 'result':
        await _recordResult(match);
      case 'schedule':
        await _pickSchedule(match);
      case 'details':
        _showMatchDetails(match);
      case 'swap':
        _pickSwapParticipant(match);
    }
  }

  void _pickSwapParticipant(AppMatch match) async {
    final admin = _adminController;
    if (admin == null) return;

    final slot = await showDialog<int>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _SwapParticipantDialog(match: match),
    );

    if (slot != null && mounted) {
      admin.startManualSwap(match, slot);
    }
  }

  Future<String?> _showMatchAdminSheet(AppMatch match) {
    final canRecordResult = match.isReady && !match.isBye;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                _buildSheetAction(icon: Icons.visibility_rounded, label: 'Ver detalle', onTap: () => Navigator.pop(context, 'details')),
                if (_adminController?.isDraftMode == true && match.round == 0)
                  _buildSheetAction(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Intercambiar',
                    onTap: () => Navigator.pop(context, 'swap'),
                  ),
                _buildSheetAction(
                  icon: Icons.emoji_events_rounded,
                  label: 'Registrar resultado',
                  enabled: canRecordResult,
                  onTap: () => Navigator.pop(context, 'result'),
                ),
                _buildSheetAction(
                  icon: Icons.schedule_rounded,
                  label: 'Editar horario',
                  enabled: !match.isCompleted && !match.isBye,
                  onTap: () => Navigator.pop(context, 'schedule'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Match details ──────────────────────────────────────────────────────

  void _showMatchDetails(AppMatch match) {
    final admin = _adminController;
    final roundName = admin != null
        ? admin.roundName(match.round)
        : _controller.roundName(match.round, _controller.selectedBracket?.totalRounds ?? 0);

    MatchDetailPanel.show(
      context,
      match,
      matchNumber: match.matchOrder,
      roundName: roundName,
      categoryName: match.categoryId != null
          ? (admin?.activeBracket?.categoryName ?? _controller.selectedBracket?.categoryName)
          : null,
    );
  }

  // ── Record result ──────────────────────────────────────────────────────

  Future<void> _recordResult(AppMatch match) async {
    if (!match.isReady || match.isBye) return;
    final result = await MatchResultDialog.show(context, match);
    if (result == null) return;
    await _adminController!.recordMatchResult(
      matchId: match.id,
      winnerId: result.winnerId,
      loserId: result.loserId,
      scoreParticipant1: result.scoreParticipant1,
      scoreParticipant2: result.scoreParticipant2,
    );
  }

  // ── Schedule picker ────────────────────────────────────────────────────

  Future<void> _pickSchedule(AppMatch match) async {
    final initial = match.scheduledAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6C63FF), surface: Color(0xFF1E293B))),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6C63FF), surface: Color(0xFF1E293B))),
        child: child!,
      ),
    );
    if (time == null) return;
    await _adminController!.updateMatchSchedule(
      matchId: match.id,
      scheduledAt: DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  // ── Admin buttons section ──────────────────────────────────────────────

  Widget _buildAdminButtonsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ExpansionTile(
            title: const Text('Opciones de Administración', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white60, size: 20),
            iconColor: Colors.white60,
            collapsedIconColor: Colors.white60,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await _showConfirmDialog(title: '¿Regenerar bracket?', message: 'Se eliminarán todos los matches actuales y se generará un nuevo bracket.');
                        if (ok) _adminController!.regenerateBracket();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Regenerar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB347).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFFFFB347),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: const Color(0xFFFFB347).withValues(alpha: 0.3))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await _showConfirmDialog(title: '¿Publicar bracket?', message: 'Una vez publicado, no se podrá regenerar. Los participantes serán notificados.');
                        if (ok) _adminController!.publishBracket();
                      },
                      icon: const Icon(Icons.publish_rounded, size: 16),
                      label: const Text('Publicar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF22C55E),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: const Color(0xFF22C55E).withValues(alpha: 0.3))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status badge ───────────────────────────────────────────────────────

  Widget _buildStatusBadge() {
    final bracket = _adminController!.activeBracket!;
    final Color color;
    final String text;

    if (bracket.status.isDraft) {
      color = const Color(0xFFF59E0B);
      text = 'BORRADOR – Solo visible para admins';
    } else if (bracket.status.isPublished) {
      color = const Color(0xFF22C55E);
      text = 'PUBLICADO';
    } else if (bracket.status.isActive) {
      color = const Color(0xFF6C63FF);
      text = 'EN CURSO';
    } else {
      color = Colors.white.withValues(alpha: 0.5);
      text = bracket.status.label.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }

  // ── No bracket admin ───────────────────────────────────────────────────

  Widget _buildNoBracketAdmin() {
    final isGenerating = _adminController!.state == BracketAdminState.generating;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6C63FF).withValues(alpha: 0.1)),
              child: const Icon(Icons.account_tree_rounded, size: 40, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 24),
            const Text('Sin bracket generado', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'Genera el bracket automáticamente a partir de los participantes inscritos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220, height: 50,
              child: ElevatedButton(
                onPressed: isGenerating ? null : () => _adminController!.generateBracket(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  disabledBackgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Generar bracket', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Common states ──────────────────────────────────────────────────────

  Widget _buildLoading() => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));

  Widget _buildEmpty() => Center(
    child: Text('No hay brackets disponibles.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15)),
  );

  Widget _buildError(String? message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(message ?? 'Error desconocido', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
        ],
      ),
    ),
  );

  // ── Helpers ────────────────────────────────────────────────────────────

  void _showAdminMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final admin = _adminController;
      if (admin == null) return;

      if (admin.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(admin.successMessage!),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        admin.clearMessages();
      }

      if (admin.errorMessage != null && admin.state == BracketAdminState.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(admin.errorMessage!),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        admin.clearMessages();
      }
    });
  }

  Widget _buildSheetAction({required IconData icon, required String label, required VoidCallback onTap, bool enabled = true}) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: enabled ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.2)),
      title: Text(label, style: TextStyle(color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
      onTap: enabled ? onTap : null,
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      width: 42, height: 4,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white.withValues(alpha: 0.16)),
    );
  }

  Future<bool> _showConfirmDialog({required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.5)),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    )
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SwapParticipantDialog
// ─────────────────────────────────────────────────────────────────────────────

class _SwapParticipantDialog extends StatefulWidget {
  const _SwapParticipantDialog({required this.match});
  final AppMatch match;

  @override
  State<_SwapParticipantDialog> createState() => _SwapParticipantDialogState();
}

class _SwapParticipantDialogState extends State<_SwapParticipantDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  int? _hovered;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p1 = widget.match.participant1Name ?? 'Participante 1';
    final p2 = widget.match.participant2Name ?? 'Participante 2';
    final photo1 = widget.match.participant1PhotoUrl;
    final photo2 = widget.match.participant2PhotoUrl;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D2B).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Intercambiar participante',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Selecciona quién quieres mover',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Divisor VS ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.08),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.08),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Cards de participantes ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        children: [
                          _ParticipantSelectCard(
                            name: p1,
                            photoUrl: photo1,
                            slot: 1,
                            isHovered: _hovered == 1,
                            onHoverChange: (v) =>
                                setState(() => _hovered = v ? 1 : null),
                            onTap: () => Navigator.pop(context, 1),
                          ),
                          const SizedBox(height: 10),
                          _ParticipantSelectCard(
                            name: p2,
                            photoUrl: photo2,
                            slot: 2,
                            isHovered: _hovered == 2,
                            onHoverChange: (v) =>
                                setState(() => _hovered = v ? 2 : null),
                            onTap: () => Navigator.pop(context, 2),
                          ),
                          const SizedBox(height: 20),
                          // Tip informativo
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF6C63FF),
                                  size: 15,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tras seleccionar, toca otro participante del bracket para completar el intercambio.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.55),
                                      fontSize: 11.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ParticipantSelectCard
// ─────────────────────────────────────────────────────────────────────────────

class _ParticipantSelectCard extends StatelessWidget {
  const _ParticipantSelectCard({
    required this.name,
    required this.photoUrl,
    required this.slot,
    required this.isHovered,
    required this.onHoverChange,
    required this.onTap,
  });

  final String name;
  final String? photoUrl;
  final int slot;
  final bool isHovered;
  final ValueChanged<bool> onHoverChange;
  final VoidCallback onTap;

  Color _accentColor() {
    const colors = [
      Color(0xFF6C63FF),
      Color(0xFF00D4FF),
      Color(0xFFFF6B9D),
      Color(0xFF22C55E),
      Color(0xFFFFB347),
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Avatar igual al de MatchDetailPanel: foto de red → fallback con iniciales
  Widget _buildAvatar(Color accent) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Cuando hay foto: fondo neutro; sin foto: gradiente de color
        gradient: hasPhoto
            ? null
            : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.55)],
        ),
        color: hasPhoto ? Colors.white.withValues(alpha: 0.06) : null,
        border: Border.all(
          color: isHovered
              ? accent.withValues(alpha: 0.55)
              : accent.withValues(alpha: 0.30),
          width: isHovered ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isHovered ? 0.4 : 0.2),
            blurRadius: isHovered ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent.withValues(alpha: 0.6),
              ),
            ),
          ),
          errorBuilder: (_, __, ___) => _buildInitialsFallback(accent),
        )
            : _buildInitialsFallback(accent),
      ),
    );
  }

  Widget _buildInitialsFallback(Color accent) {
    return Center(
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();

    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isHovered
                ? accent.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? accent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: isHovered
                ? [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Row(
            children: [
              // Avatar: foto de perfil con fallback a iniciales
              _buildAvatar(accent),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Posición $slot',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha animada
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isHovered
                      ? accent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: isHovered
                      ? accent
                      : Colors.white.withValues(alpha: 0.25),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}