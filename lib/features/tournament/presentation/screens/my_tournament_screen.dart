import 'package:flutter/material.dart';

import '../../../adminTournament/presentation/screens/tournament_management_screen.dart';
import 'my_tournaments/old_tournament_detail_screen.dart';
import '../../domain/helpers/tournament_champion_resolver.dart';
import '../../../home/presentation/widgets/tournament_card.dart';
import '../../data/model/app_tournament.dart';
import '../../data/model/enums_tournament.dart';
import '../../data/model/tournament_draft.dart';
import '../../data/repositories/tournament_draft_repository.dart';
import '../../data/services/shared_preferences_tournament_draft_repository.dart';
import '../controllers/my_tournaments_list_controller.dart';
import 'create_tournament/create_tournament_screen.dart';
import 'create_tournament/form_tournament_screen.dart';

class MyTournamentScreen extends StatefulWidget {
  const MyTournamentScreen({super.key});

  @override
  State<MyTournamentScreen> createState() => _MyTournamentScreenState();
}

class _MyTournamentScreenState extends State<MyTournamentScreen> {
  late final MyTournamentsListController _controller;
  late final TournamentDraftRepository _draftRepository;
  List<TournamentDraft> _localDrafts = const [];
  bool _isLoadingDrafts = false;
  bool _isCreatingTournament = false;
  bool _showOldTournaments = false;

  @override
  void initState() {
    super.initState();
    _controller = MyTournamentsListController();
    _draftRepository = SharedPreferencesTournamentDraftRepository();
    _loadLocalDrafts();
  }

  void _toggleCreateMode() {
    setState(() {
      _isCreatingTournament = !_isCreatingTournament;
    });
    if (!_isCreatingTournament) {
      _loadLocalDrafts();
    }
  }

  Future<void> _loadLocalDrafts() async {
    final uid = _controller.currentUid;
    if (uid == null) return;
    setState(() => _isLoadingDrafts = true);
    try {
      final drafts = await _draftRepository.getDraftsForOwner(uid);
      if (mounted) {
        setState(() => _localDrafts = drafts);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDrafts = false);
      }
    }
  }

  Future<void> _openDraft(TournamentDraft draft) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormTournamentScreen(initialDraft: draft),
      ),
    );
    if (mounted) {
      _loadLocalDrafts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                        ).createShader(b),
                        child: Text(
                          _isCreatingTournament
                              ? 'Crear Torneo'
                              : 'Mis Torneos',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isCreatingTournament
                            ? 'Configura tu nuevo evento'
                            : 'Torneos que administras o creaste',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Container(
                      key: ValueKey(_isCreatingTournament),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isCreatingTournament
                              ? [
                                  const Color(0xFF4A4480),
                                  const Color(0xFF008FA8),
                                ]
                              : [
                                  const Color(0xFF6C63FF),
                                  const Color(0xFF00D4FF),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.35),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isCreatingTournament
                              ? Icons.close_rounded
                              : Icons.add_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _toggleCreateMode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isCreatingTournament
                    ? const CreateTournamentScreen(
                        key: ValueKey('create_screen'),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('list_screen'),
                        child: _buildTournamentList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentList() {
    if (_controller.currentUid == null) {
      return const _TournamentEmptyState(
        title: 'Inicia sesión',
        message: 'Necesitas iniciar sesión para ver tus torneos.',
        icon: Icons.lock_outline_rounded,
      );
    }

    // Combine both streams using nested StreamBuilders
    return StreamBuilder<List<AppTournament>>(
      stream: _controller.watchAdministeredTournaments(),
      builder: (context, activeSnapshot) {
        return StreamBuilder<List<AppTournament>>(
          stream: _controller.watchCompletedTournaments(),
          builder: (context, completedSnapshot) {
            final isLoading =
                activeSnapshot.connectionState == ConnectionState.waiting &&
                completedSnapshot.connectionState == ConnectionState.waiting;

            if (isLoading) {
              return const _TournamentLoadingState();
            }

            if (activeSnapshot.hasError) {
              return _TournamentErrorState(
                message: '${activeSnapshot.error}',
              );
            }

            final activeTournaments = activeSnapshot.data ?? [];
            final completedTournaments = completedSnapshot.data ?? [];

            final hasContent =
                activeTournaments.isNotEmpty ||
                completedTournaments.isNotEmpty ||
                _localDrafts.isNotEmpty;

            if (!hasContent) {
              return const _TournamentEmptyState(
                title: 'Sin torneos',
                message: 'Aún no has creado ni administras ningún torneo.',
                icon: Icons.admin_panel_settings_outlined,
              );
            }

            return _TournamentListBody(
              activeTournaments: activeTournaments,
              completedTournaments: completedTournaments,
              localDrafts: _localDrafts,
              isLoadingDrafts: _isLoadingDrafts,
              currentUid: _controller.currentUid,
              showOldTournaments: _showOldTournaments,
              onToggleOldTournaments: () {
                setState(() => _showOldTournaments = !_showOldTournaments);
              },
              onOpenDraft: _openDraft,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _TournamentListBody  –  Cuerpo principal con secciones separadas
// ─────────────────────────────────────────────────────────────────────────────

class _TournamentListBody extends StatelessWidget {
  const _TournamentListBody({
    required this.activeTournaments,
    required this.completedTournaments,
    required this.localDrafts,
    required this.isLoadingDrafts,
    required this.currentUid,
    required this.showOldTournaments,
    required this.onToggleOldTournaments,
    required this.onOpenDraft,
  });

  final List<AppTournament> activeTournaments;
  final List<AppTournament> completedTournaments;
  final List<TournamentDraft> localDrafts;
  final bool isLoadingDrafts;
  final String? currentUid;
  final bool showOldTournaments;
  final VoidCallback onToggleOldTournaments;
  final Future<void> Function(TournamentDraft) onOpenDraft;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── Sección: Mis antiguos torneos (collapsible) ─────────────────────
        if (completedTournaments.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _OldTournamentsHeader(
              count: completedTournaments.length,
              isExpanded: showOldTournaments,
              onToggle: onToggleOldTournaments,
            ),
          ),
          if (showOldTournaments)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final t = completedTournaments[index];
                    return _CompletedTournamentCard(
                      tournament: t,
                      currentUid: currentUid,
                      animationDelay: Duration(milliseconds: 60 * index),
                    );
                  },
                  childCount: completedTournaments.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                color: Colors.white.withValues(alpha: 0.07),
                height: 28,
              ),
            ),
          ),
        ],

        // ── Sección: Borradores locales ─────────────────────────────────────
        if (localDrafts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _LocalDraftsHeader(isLoading: isLoadingDrafts),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final draft = localDrafts[index];
                  return _LocalDraftCard(
                    draft: draft,
                    onTap: () => onOpenDraft(draft),
                  );
                },
                childCount: localDrafts.length,
              ),
            ),
          ),
        ],

        // ── Sección: Torneos activos ────────────────────────────────────────
        if (activeTournaments.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _PublishedHeader(count: activeTournaments.length),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tournament = activeTournaments[index];
                  final isCreator = tournament.organizerUid == currentUid;
                  return TournamentCard(
                    tournament: tournament,
                    isMyTournament: isCreator,
                    animationDelay: Duration(milliseconds: 70 * index),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TournamentManagementScreen(tournament: tournament),
                      ),
                    ),
                  );
                },
                childCount: activeTournaments.length,
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _OldTournamentsHeader  –  Banner expandible para torneos completados
// ─────────────────────────────────────────────────────────────────────────────

class _OldTournamentsHeader extends StatelessWidget {
  const _OldTournamentsHeader({
    required this.count,
    required this.isExpanded,
    required this.onToggle,
  });

  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFFB0A8FF).withValues(alpha: 0.08),
          highlightColor: const Color(0xFFB0A8FF).withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6C63FF).withValues(alpha: 0.10),
                  const Color(0xFFB0A8FF).withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                // Icon with gradient container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6C63FF).withValues(alpha: 0.25),
                        const Color(0xFFB0A8FF).withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFFB0A8FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                        ).createShader(b),
                        child: const Text(
                          'Mis antiguos torneos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count torneo${count == 1 ? '' : 's'} finalizado${count == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Expand/collapse indicator
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFFB0A8FF).withValues(alpha: 0.8),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _CompletedTournamentCard  –  Tarjeta de torneo histórico (muted)
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedTournamentCard extends StatefulWidget {
  const _CompletedTournamentCard({
    required this.tournament,
    required this.currentUid,
    required this.animationDelay,
  });

  final AppTournament tournament;
  final String? currentUid;
  final Duration animationDelay;

  @override
  State<_CompletedTournamentCard> createState() =>
      _CompletedTournamentCardState();
}

class _CompletedTournamentCardState extends State<_CompletedTournamentCard> {
  late final Future<OldTournamentSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture =
        TournamentChampionResolver().resolve(widget.tournament.id);
  }

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final isCancelled = tournament.status == TournamentStatus.cancelled;
    final badgeColor =
        isCancelled ? const Color(0xFFFF6B6B) : const Color(0xFF00D4A8);
    final badgeLabel = isCancelled ? 'CANCELADO' : 'COMPLETADO';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OldTournamentDetailScreen(tournament: tournament),
            ),
          ),
          borderRadius: BorderRadius.circular(22),
          splashColor: const Color(0xFF00D4A8).withValues(alpha: 0.08),
          highlightColor: const Color(0xFF00D4A8).withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  badgeColor.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FutureBuilder<OldTournamentSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                final summary = snapshot.data;
                final formatLabel = summary?.formatShortLabel ?? '—';
                final finishedAt =
                    summary?.completedAt ?? tournament.updatedAt;
                final champion = summary?.championName;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                badgeColor.withValues(alpha: 0.22),
                                badgeColor.withValues(alpha: 0.08),
                              ],
                            ),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            isCancelled
                                ? Icons.cancel_outlined
                                : Icons.emoji_events_rounded,
                            color: badgeColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tournament.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  color: badgeColor.withValues(alpha: 0.14),
                                  border: Border.all(
                                    color: badgeColor.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${tournament.participantCount} participantes · $formatLabel',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Finalizado: ${_formatDate(finishedAt)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (champion != null && champion.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Ganador: $champion',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: badgeColor.withValues(alpha: 0.95),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Ver detalles',
                          style: TextStyle(
                            color: badgeColor.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: badgeColor.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Existing helpers (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _TournamentLoadingState extends StatelessWidget {
  const _TournamentLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation(Color(0xFF00D4FF)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cargando torneos...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalDraftsHeader extends StatelessWidget {
  const _LocalDraftsHeader({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
      child: Row(
        children: [
          const Icon(Icons.edit_document, color: Color(0xFF00D4FF), size: 18),
          const SizedBox(width: 8),
          const Text(
            'Borradores locales',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          if (isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _PublishedHeader extends StatelessWidget {
  const _PublishedHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Text(
        'Publicados ($count)',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LocalDraftCard extends StatelessWidget {
  const _LocalDraftCard({required this.draft, required this.onTap});

  final TournamentDraft draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = draft.name?.trim().isNotEmpty == true
        ? draft.name!.trim()
        : 'Borrador sin título';
    final subtitle = draft.eventDate == null
        ? 'Última edición: ${_formatDate(draft.updatedAt)}'
        : 'Evento: ${_formatDate(draft.eventDate!)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF00D4FF).withValues(alpha: 0.07),
          highlightColor: const Color(0xFF00D4FF).withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00D4FF).withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Icono con gradiente ──────────────────────────────────────
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF00D4FF).withValues(alpha: 0.22),
                        const Color(0xFF6C63FF).withValues(alpha: 0.14),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF00D4FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Título y subtítulo ───────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge "Borrador"
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF00D4FF).withValues(
                                alpha: 0.12,
                              ),
                              border: Border.all(
                                color: const Color(0xFF00D4FF).withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Borrador',
                              style: TextStyle(
                                color: Color(0xFF00D4FF),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            draft.eventDate == null
                                ? Icons.update_rounded
                                : Icons.calendar_today_rounded,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.38),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // ── Flecha ───────────────────────────────────────────────────
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _TournamentErrorState extends StatelessWidget {
  const _TournamentErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    debugPrint(message);
    return _TournamentEmptyState(
      title: 'Ups…',
      message: message,
      icon: Icons.error_outline_rounded,
    );
  }
}

class _TournamentEmptyState extends StatelessWidget {
  const _TournamentEmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ).createShader(b),
              child: Icon(icon, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
              ).createShader(b),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
