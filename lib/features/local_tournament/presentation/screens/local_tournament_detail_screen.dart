import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/local_athlete.dart';
import '../../data/models/local_match.dart';
import '../../data/models/local_tournament.dart';
import '../controllers/local_tournament_controller.dart';
import 'local_tournament_bracket_screen.dart';
import 'local_tournament_athletes_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalTournamentDetailScreen  ·  Presentation
//
//  Pantalla de detalle de un torneo local.
//  Muestra: portada, nombre, estado, atletas inscritos y acceso al bracket.
//  El organizador puede gestionar atletas, cambiar la portada y
//  generar/ver el bracket.
// ─────────────────────────────────────────────────────────────────────────────

class LocalTournamentDetailScreen extends StatefulWidget {
  const LocalTournamentDetailScreen({super.key, required this.tournament});

  final LocalTournament tournament;

  @override
  State<LocalTournamentDetailScreen> createState() =>
      _LocalTournamentDetailScreenState();
}

class _LocalTournamentDetailScreenState
    extends State<LocalTournamentDetailScreen> {
  late final LocalTournamentController _controller;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _controller = LocalTournamentController(tournament: widget.tournament);
    unawaited(_controller.repairLegacyAutoByes());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        _handleMessages();
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A1A),
          extendBodyBehindAppBar: true,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildContent()),
            ],
          ),
        );
      },
    );
  }

  void _handleMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_controller.successMessage!)),
              ],
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _controller.clearMessages();
      }
      if (_controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_controller.errorMessage!)),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _controller.clearMessages();
      }
    });
  }

  Widget _buildAppBar() {
    final current = _controller.current;
    final coverPath = current.coverImagePath;
    final hasValidCover =
        coverPath != null &&
        coverPath.isNotEmpty &&
        File(coverPath).existsSync();

    return SliverAppBar(
      expandedHeight: hasValidCover ? 220 : 140,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.photo_camera_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          onPressed: _isPickingImage ? null : _pickCoverImage,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildCoverBackground(hasValidCover, coverPath),
        title: Text(
          current.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsetsDirectional.fromSTEB(60, 0, 60, 16),
      ),
    );
  }

  Widget _buildCoverBackground(bool hasValidCover, String? coverPath) {
    if (hasValidCover) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(coverPath!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _defaultCoverBg(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0F172A).withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // Botón eliminar portada
          Positioned(
            bottom: 56,
            right: 16,
            child: GestureDetector(
              onTap: _removeCoverImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Quitar portada',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _defaultCoverBg();
  }

  Widget _defaultCoverBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 48,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Añadir portada',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
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

  Widget _buildContent() {
    final current = _controller.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Estado y deporte ─────────────────────────────────────────────
          _buildStatusRow(current),
          const SizedBox(height: 24),

          // ── Acciones principales ──────────────────────────────────────────
          _buildPrimaryActions(current),
          const SizedBox(height: 28),

          // ── Atletas ───────────────────────────────────────────────────────
          _buildAthletesSection(current),
          const SizedBox(height: 24),

          // ── Campeón (si el torneo ha terminado) ───────────────────────────
          if (current.status == LocalTournamentStatus.finished &&
              current.champion != null)
            _buildChampionSection(current.champion!),
        ],
      ),
    );
  }

  Widget _buildStatusRow(LocalTournament current) {
    final (color, label) = switch (current.status) {
      LocalTournamentStatus.setup => (const Color(0xFF6C63FF), 'Configurando'),
      LocalTournamentStatus.inProgress => (const Color(0xFFF59E0B), 'En curso'),
      LocalTournamentStatus.finished => (const Color(0xFF22C55E), 'Finalizado'),
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (current.sport != null) ...[
          const SizedBox(width: 10),
          Icon(
            Icons.sports_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 4),
          Text(
            current.sport!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
        const Spacer(),
        Text(
          '${current.athletes.length} atletas',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActions(LocalTournament current) {
    return Column(
      children: [
        // Botón principal: Ver/Generar bracket
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: current.hasBracket ? _openBracket : _generateBracket,
            icon: Icon(
              current.hasBracket
                  ? Icons.account_tree_rounded
                  : Icons.auto_fix_high_rounded,
              size: 20,
            ),
            label: Text(
              current.hasBracket ? 'Ver bracket' : 'Generar bracket',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (current.hasBracket) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _confirmRegenerateBracket,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Regenerar bracket',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.6),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        // Botón: Gestionar atletas
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _openAthletes,
            icon: const Icon(Icons.people_rounded, size: 16),
            label: const Text(
              'Gestionar atletas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00D4FF),
              side: BorderSide(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAthletesSection(LocalTournament current) {
    if (current.athletes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_add_rounded,
              size: 32,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 10),
            Text(
              'Sin atletas registrados',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca "Gestionar atletas" para añadir participantes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Atletas inscritos',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              ),
              child: Text(
                '${current.athletes.length}',
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: current.athletes
              .take(12)
              .map((a) => _AthleteChip(athlete: a))
              .toList(),
        ),
        if (current.athletes.length > 12) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openAthletes,
            child: Text(
              '+ ${current.athletes.length - 12} más',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChampionSection(LocalMatch final_) {
    final champion = final_.winner;
    if (champion == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.15),
            const Color(0xFFFF8C00).withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFFD700),
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            '¡Campeón!',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            champion.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> _pickCoverImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picked = await _controller.pickImageForPreview();
      if (picked == null || !mounted) return;

      // Mostrar diálogo de previsualización antes de confirmar
      final confirmed = await _showCoverPreviewDialog(File(picked.path));
      if (confirmed == true && mounted) {
        await _controller.setCoverImage(picked);
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _removeCoverImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
              const SizedBox(height: 14),
              const Text(
                'Quitar portada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Eliminar la portada actual y volver a la imagen predeterminada?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text(
                        'Quitar',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

    if (confirmed == true) {
      await _controller.removeCoverImage();
    }
  }

  Future<bool?> _showCoverPreviewDialog(File imageFile) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vista previa de la portada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Descartar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmar portada',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

  Future<void> _openBracket() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalTournamentBracketScreen(controller: _controller),
      ),
    );
  }

  Future<void> _generateBracket() async {
    if (_controller.athletes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Añade atletas antes de generar el bracket.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    await _controller.generateBracket();
    if (mounted && _controller.hasBracket) {
      await _openBracket();
    }
  }

  Future<void> _confirmRegenerateBracket() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh_rounded,
                color: Color(0xFFF59E0B),
                size: 36,
              ),
              const SizedBox(height: 14),
              const Text(
                '¿Regenerar bracket?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Se perderán todos los resultados registrados. Esta acción no se puede deshacer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
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
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Regenerar',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

    if (ok == true && mounted) {
      await _controller.generateBracket();
      if (mounted && _controller.hasBracket) {
        await _openBracket();
      }
    }
  }

  Future<void> _openAthletes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalTournamentAthletesScreen(controller: _controller),
      ),
    );
  }
}

// ── Chip de atleta ─────────────────────────────────────────────────────────────

class _AthleteChip extends StatelessWidget {
  const _AthleteChip({required this.athlete});

  final LocalAthlete athlete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                athlete.name.isNotEmpty ? athlete.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            athlete.name,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
