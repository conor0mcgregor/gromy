import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/models/app_match.dart';
import '../controllers/bracket_controller.dart';
import '../controllers/bracket_admin_controller.dart';
import '../widgets/bracket_board.dart';
import '../widgets/category_selector.dart';
import '../widgets/match_result_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BracketScreen  ·  Presentation
//
//  Pantalla principal de visualización del bracket.
//  Usa InteractiveViewer con constrained: false para crear un plano
//  2D gigante navegable con zoom y paneo libre.
//
//  Soporta:
//    - Visualización pública (solo lectura)
//    - Modo admin (edición, resultados, publicación)
//    - Categorías múltiples
//    - Actualización en tiempo real via streams
// ─────────────────────────────────────────────────────────────────────────────

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
  String? _pendingSwapMatchId;
  int? _pendingSwapSlot;

  @override
  void initState() {
    super.initState();
    _controller = BracketController(tournamentId: widget.tournamentId);

    if (widget.isAdmin) {
      _adminController = BracketAdminController(
        tournamentId: widget.tournamentId,
      );
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
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Enfrentamientos',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
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
            child: Icon(
              Icons.center_focus_strong_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          onPressed: () {
            _transformationController.value = Matrix4.identity();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Body público ──────────────────────────────────────────────────────

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
            roundNameBuilder: (i) => _controller.roundName(
              i,
              _controller.selectedBracket?.totalRounds ?? 0,
            ),
            categories: _controller.availableCategories,
            selectedCategory: _controller.selectedBracket?.categoryName,
            onCategorySelected: _controller.selectCategory,
            isAdmin: false,
          ),
        };
      },
    );
  }

  // ── Body admin ────────────────────────────────────────────────────────

  Widget _buildAdminBody() {
    return ListenableBuilder(
      listenable: _adminController!,
      builder: (context, _) {
        // Mostrar snackbar de mensajes
        _showAdminMessages();

        if (!_adminController!.hasBracket) {
          return _buildNoBracketAdmin();
        }

        final admin = _adminController!;
        final isLoading =
            admin.state == BracketAdminState.loading ||
            admin.state == BracketAdminState.generating;

        if (isLoading && admin.matches.isEmpty) {
          return _buildLoading();
        }

        return _buildBracketView(
          matchesByRound: admin.matchesByRound,
          totalRounds: admin.activeBracket?.totalRounds ?? 0,
          roundNameBuilder: admin.roundName,
          categories: admin.brackets
              .where(
                (b) => b.categoryName != null && b.categoryName!.isNotEmpty,
              )
              .map((b) => b.categoryName!)
              .toSet()
              .toList(),
          selectedCategory: admin.activeBracket?.categoryName,
          onCategorySelected: (cat) {
            final bracket = admin.brackets.firstWhere(
              (b) => b.categoryName == cat,
            );
            admin.selectBracket(bracket);
          },
          isAdmin: true,
        );
      },
    );
  }

  // ── Vista compartida del bracket ──────────────────────────────────────

  Widget _buildBracketView({
    required Map<int, List<AppMatch>> matchesByRound,
    required int totalRounds,
    required String Function(int) roundNameBuilder,
    required List<String> categories,
    required String? selectedCategory,
    required void Function(String) onCategorySelected,
    required bool isAdmin,
  }) {
    return Column(
      children: [
        // Padding top para AppBar
        SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),


        _buildAdminActions(),
        const SizedBox(height: 8),

        // Status badge (admin)
        if (isAdmin && _adminController?.activeBracket != null)
          _buildStatusBadge(),

        // Selector de categorías
        CategorySelector(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
        ),

        if (categories.length > 1) const SizedBox(height: 12),

        // Bracket interactivo
        Expanded(
          child: InteractiveViewer(
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
              onMatchTap: isAdmin ? _onMatchTapAdmin : _showMatchDetails,
            ),
          ),
        ),
      ],
    );
  }

  // ── Acciones admin ────────────────────────────────────────────────────


  Widget _buildAdminActions() {
    return PopupMenuButton<String>(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      itemBuilder: (context) => [
        if (_adminController!.isDraftMode) ...[
          _buildMenuItem(
            icon: Icons.refresh_rounded,
            label: 'Regenerar bracket',
            value: 'regenerate',
            color: const Color(0xFFFFB347),
          ),
          _buildMenuItem(
            icon: Icons.publish_rounded,
            label: 'Publicar bracket',
            value: 'publish',
            color: const Color(0xFF22C55E),
          ),
        ],
      ],
      onSelected: (value) async {
        switch (value) {
          case 'regenerate':
            final confirm = await _showConfirmDialog(
              title: '¿Regenerar bracket?',
              message:
              'Se eliminarán todos los matches actuales y se generará un nuevo bracket.',
            );
            if (confirm) _adminController!.regenerateBracket();
          case 'publish':
            final confirm = await _showConfirmDialog(
              title: '¿Publicar bracket?',
              message:
              'Una vez publicado, no se podrá regenerar. Los participantes serán notificados.',
            );
            if (confirm) _adminController!.publishBracket();
        }
      },
      // AQUÍ ESTÁ EL CAMBIO
      child: Container(
        // Añadimos margen horizontal para separarlo de los bordes del móvil
        margin: const EdgeInsets.symmetric(horizontal: 18),
        width: double.infinity,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 50),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              size: 16,
              color: Color(0xFFF59E0B),
            ),
            SizedBox(width: 10),
            Text(
              'Administrar',
              style: TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        )
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final bracket = _adminController!.activeBracket!;
    final Color color;
    final String text;

    if (bracket.status.isDraft) {
      color = const Color(0xFFF59E0B);
      text = 'BORRADOR - Solo visible para admins';
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Match tap admin ───────────────────────────────────────────────────

  void _onMatchTapAdmin(AppMatch match) async {
    final action = await _showMatchAdminSheet(match);
    if (!mounted || action == null) return;

    switch (action) {
      case 'result':
        await _recordResult(match);
        break;
      case 'schedule':
        await _pickSchedule(match);
        break;
      case 'details':
        _showMatchDetails(match);
        break;
      case 'swap1':
        _handleSwapSelection(match, 1);
        break;
      case 'swap2':
        _handleSwapSelection(match, 2);
        break;
    }
  }

  Future<String?> _showMatchAdminSheet(AppMatch match) {
    final canRecordResult = match.isReady && !match.isBye;
    final canSwap = _adminController?.isDraftMode == true && match.round == 0;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHandle(),
                _buildSheetAction(
                  icon: Icons.visibility_rounded,
                  label: 'Ver detalle',
                  onTap: () => Navigator.pop(context, 'details'),
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
                if (canSwap) ...[
                  _buildSheetAction(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Intercambiar participante superior',
                    onTap: () => Navigator.pop(context, 'swap1'),
                  ),
                  _buildSheetAction(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Intercambiar participante inferior',
                    onTap: () => Navigator.pop(context, 'swap2'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

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

  Future<void> _pickSchedule(AppMatch match) async {
    final initial = match.scheduledAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    await _adminController!.updateMatchSchedule(
      matchId: match.id,
      scheduledAt: DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _handleSwapSelection(AppMatch match, int slot) {
    if (_pendingSwapMatchId == null || _pendingSwapSlot == null) {
      setState(() {
        _pendingSwapMatchId = match.id;
        _pendingSwapSlot = slot;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecciona otro slot para intercambiar con '
            '${_slotName(match, slot)}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final matchId1 = _pendingSwapMatchId!;
    final slot1 = _pendingSwapSlot!;
    setState(() {
      _pendingSwapMatchId = null;
      _pendingSwapSlot = null;
    });

    _adminController!.swapParticipants(
      matchId1: matchId1,
      slotInMatch1: slot1,
      matchId2: match.id,
      slotInMatch2: slot,
    );
  }

  void _showMatchDetails(AppMatch match) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _buildSheetHandle()),
                const SizedBox(height: 10),
                const Text(
                  'Detalle del enfrentamiento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildParticipantDetail(
                  title: match.participant1Name ?? 'Por definir',
                  type: match.participant1Type?.name,
                  memberNames: match.participant1MemberNames,
                ),
                const SizedBox(height: 10),
                _buildParticipantDetail(
                  title: match.participant2Name ?? 'Por definir',
                  type: match.participant2Type?.name,
                  memberNames: match.participant2MemberNames,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticipantDetail({
    required String title,
    required String? type,
    required List<String> memberNames,
  }) {
    final isTeam = type == 'team';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTeam ? Icons.groups_rounded : Icons.person_rounded,
                size: 18,
                color: const Color(0xFF6C63FF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (isTeam && memberNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: memberNames
                  .map(
                    (name) => Chip(
                      label: Text(name),
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      backgroundColor: const Color(
                        0xFF6C63FF,
                      ).withValues(alpha: 0.16),
                      side: BorderSide(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSheetAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ListTile(
      enabled: enabled,
      leading: Icon(
        icon,
        color: enabled
            ? const Color(0xFF6C63FF)
            : Colors.white.withValues(alpha: 0.2),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: enabled ? onTap : null,
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.16),
      ),
    );
  }

  String _slotName(AppMatch match, int slot) {
    final name = slot == 1 ? match.participant1Name : match.participant2Name;
    return name ?? 'slot $slot';
  }

  // ── No bracket admin (generar) ────────────────────────────────────────

  Widget _buildNoBracketAdmin() {
    final isGenerating =
        _adminController!.state == BracketAdminState.generating;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.account_tree_rounded,
                size: 40,
                color: Color(0xFF6C63FF),
              ),
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
            const SizedBox(height: 12),
            Text(
              'Genera el bracket automáticamente a partir de los participantes inscritos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton(
                onPressed: isGenerating
                    ? null
                    : () => _adminController!.generateBracket(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  disabledBackgroundColor: const Color(
                    0xFF6C63FF,
                  ).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_fix_high_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Generar bracket',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Estados comunes ───────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'No hay brackets disponibles.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: const Color(0xFFEF4444).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _showAdminMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final admin = _adminController;
      if (admin == null) return;

      if (admin.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(admin.successMessage!),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        admin.clearMessages();
      }

      if (admin.errorMessage != null &&
          admin.state == BracketAdminState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(admin.errorMessage!),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        admin.clearMessages();
      }
    });
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirmar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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
      ),
    );
    return result ?? false;
  }
}
