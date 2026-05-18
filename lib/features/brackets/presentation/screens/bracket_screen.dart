import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/models/app_match.dart';
import '../controllers/bracket_controller.dart';
import '../controllers/bracket_admin_controller.dart';
import '../widgets/bracket_board.dart';
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
            ],
          ),
        ),
      ],
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
              'Mantén pulsado un participante y arrástralo para intercambiarlo',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drag & drop handler ────────────────────────────────────────────────

  void _onParticipantDropped(ParticipantDragData source, AppMatch targetMatch, int targetSlot) async {
    final admin = _adminController;
    if (admin == null || admin.state == BracketAdminState.saving) return;

    final errorMsg = await admin.swapParticipantsDragDrop(
      sourceMatch: source.match,
      sourceSlot: source.slot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
    );

    if (!mounted) return;

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
                    ),
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
