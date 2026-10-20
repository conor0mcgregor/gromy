import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/local_tournament.dart';
import '../controllers/local_tournaments_list_controller.dart';
import 'local_tournament_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalTournamentsScreen  ·  Presentation
//
//  Pantalla principal de torneos locales.
//  Lista todos los torneos locales con portada, estado y acceso rápido.
// ─────────────────────────────────────────────────────────────────────────────

class LocalTournamentsScreen extends StatefulWidget {
  const LocalTournamentsScreen({
    super.key,
    this.isEmbedded = false,
  });

  final bool isEmbedded;

  @override
  State<LocalTournamentsScreen> createState() => _LocalTournamentsScreenState();
}

class _LocalTournamentsScreenState extends State<LocalTournamentsScreen> {
  late final LocalTournamentsListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LocalTournamentsListController();
    _controller.loadTournaments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (widget.isEmbedded) {
          return Stack(
            children: [
              _buildBody(),
              Positioned(
                bottom: 120,
                right: 20,
                child: _buildFab(),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        );
      },
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: content),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                ).createShader(b),
                child: const Text(
                  'Torneos Locales',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sin conexión a internet',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Badge de torneos locales
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 13, color: Color(0xFF22C55E)),
                const SizedBox(width: 5),
                Text(
                  'Offline',
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }

    if (_controller.error != null) {
      return _buildError(_controller.error!);
    }

    if (_controller.tournaments.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: const Color(0xFF6C63FF),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: _controller.loadTournaments,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        itemCount: _controller.tournaments.length,
        itemBuilder: (context, index) {
          final tournament = _controller.tournaments[index];
          return _LocalTournamentCard(
            tournament: tournament,
            onTap: () => _openTournament(tournament),
            onDelete: () => _confirmDelete(tournament),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ).createShader(b),
              child: const Icon(Icons.emoji_events_outlined, size: 72, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Colors.white, Color(0xFFB0A8FF)],
              ).createShader(b),
              child: const Text(
                'Sin torneos locales',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Organiza torneos rápidos sin necesidad de internet.\nToca + para crear el primero.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear torneo', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _controller.loadTournaments,
              child: const Text('Reintentar', style: TextStyle(color: Color(0xFF6C63FF))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _showCreateDialog,
      backgroundColor: const Color(0xFF6C63FF),
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Nuevo torneo', style: TextStyle(fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Future<void> _openTournament(LocalTournament tournament) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalTournamentDetailScreen(tournament: tournament),
      ),
    );
    if (mounted) {
      await _controller.refreshTournament(tournament.id);
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final sportController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Nuevo torneo local',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Nombre
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Nombre del torneo',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Introduce un nombre' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                // Deporte (opcional)
                TextFormField(
                  controller: sportController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Deporte / disciplina (opcional)',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, true);
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(ctx, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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

    if (result == true && mounted) {
      final tournament = await _controller.createTournament(
        name: nameController.text,
        sport: sportController.text.trim().isEmpty ? null : sportController.text.trim(),
      );
      if (tournament != null && mounted) {
        await _openTournament(tournament);
      }
    }
  }

  Future<void> _confirmDelete(LocalTournament tournament) async {
    final confirmed = await showDialog<bool>(
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Eliminar torneo',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Eliminar "${tournament.name}"? Esta acción no se puede deshacer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancelar', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w700)),
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
      await _controller.deleteTournament(tournament.id);
    }
  }
}

// ── Tarjeta de torneo local ────────────────────────────────────────────────────

class _LocalTournamentCard extends StatelessWidget {
  const _LocalTournamentCard({
    required this.tournament,
    required this.onTap,
    required this.onDelete,
  });

  final LocalTournament tournament;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF6C63FF).withValues(alpha: 0.08),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                // ── Portada ──────────────────────────────────────────────────
                _buildCover(),
                // ── Info ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _StatusBadge(status: tournament.status),
                                if (tournament.sport != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    tournament.sport!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Text(
                                  '${tournament.athletes.length} atletas',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón eliminar
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    final coverPath = tournament.coverImagePath;

    if (coverPath != null && coverPath.isNotEmpty) {
      final file = File(coverPath);
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SizedBox(
          height: 140,
          width: double.infinity,
          child: file.existsSync()
              ? Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _defaultCover(),
                )
              : _defaultCover(),
        ),
      );
    }

    return _defaultCover();
  }

  Widget _defaultCover() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C63FF).withValues(alpha: 0.2),
              const Color(0xFF00D4FF).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.emoji_events_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }
}

// ── Status Badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final LocalTournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      LocalTournamentStatus.setup => (const Color(0xFF6C63FF), 'Configurando'),
      LocalTournamentStatus.inProgress => (const Color(0xFFF59E0B), 'En curso'),
      LocalTournamentStatus.finished => (const Color(0xFF22C55E), 'Finalizado'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
