import 'package:flutter/material.dart';

import '../../../adminTournament/presentation/screens/tournament_management_screen.dart';
import '../../../home/presentation/widgets/tournament_card.dart';
import '../../../local_tournament/presentation/screens/local_tournaments_screen.dart';
import '../../data/model/app_tournament.dart';
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
  int _selectedTab = 0; // 0 = Online, 1 = Locales

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
                            : _selectedTab == 1
                                ? 'Gestionados desde este dispositivo'
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
            if (!_isCreatingTournament)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? const Color(0xFF6C63FF)
                                      .withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 0
                                    ? const Color(0xFF6C63FF)
                                        .withValues(alpha: 0.6)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_outlined,
                                    size: 16,
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Online',
                                    style: TextStyle(
                                      color: _selectedTab == 0
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                      fontWeight: _selectedTab == 0
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? const Color(0xFF22C55E)
                                      .withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 1
                                    ? const Color(0xFF22C55E)
                                        .withValues(alpha: 0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.devices_rounded,
                                    size: 16,
                                    color: _selectedTab == 1
                                        ? const Color(0xFF22C55E)
                                        : Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Locales',
                                    style: TextStyle(
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                      fontWeight: _selectedTab == 1
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    : _selectedTab == 0
                        ? KeyedSubtree(
                            key: const ValueKey('online_list_screen'),
                            child: _buildTournamentList(),
                          )
                        : const KeyedSubtree(
                            key: ValueKey('local_tournaments_screen'),
                            child: LocalTournamentsScreen(isEmbedded: true),
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
      return _buildLocalOnlyList();
    }

    return StreamBuilder<List<AppTournament>>(
      stream: _controller.watchAdministeredTournaments(),
      builder: (context, snapshot) {
        final localContentAvailable = _localDrafts.isNotEmpty;
        if (snapshot.connectionState == ConnectionState.waiting &&
            !localContentAvailable) {
          return const _TournamentLoadingState();
        }

        if (snapshot.hasError && !localContentAvailable) {
          return _TournamentErrorState(message: snapshot.error.toString());
        }

        final managedTournaments = snapshot.data ?? [];

        if (managedTournaments.isEmpty && _localDrafts.isEmpty) {
          return const _TournamentEmptyState(
            title: 'Sin torneos',
            message: 'Aún no has creado ni administras ningún torneo online.',
            icon: Icons.admin_panel_settings_outlined,
          );
        }

        final children = <Widget>[];
        if (snapshot.hasError) {
          children.add(
            _RemoteTournamentError(message: snapshot.error.toString()),
          );
        }
        if (_localDrafts.isNotEmpty) {
          children.add(_LocalDraftsHeader(isLoading: _isLoadingDrafts));
          for (final draft in _localDrafts) {
            children.add(
              _LocalDraftCard(draft: draft, onTap: () => _openDraft(draft)),
            );
          }
        }
        if (managedTournaments.isNotEmpty) {
          children.add(_PublishedHeader(count: managedTournaments.length));
          for (var index = 0; index < managedTournaments.length; index++) {
            final tournament = managedTournaments[index];
            if (index == 0) {
              children.add(
                _TournamentListItem(
                  tournament: tournament,
                  currentUid: _controller.currentUid,
                  animationDelay: Duration.zero,
                ),
              );
            } else {
              children.add(
                TournamentCard(
                  tournament: tournament,
                  isMyTournament:
                      tournament.organizerUid == _controller.currentUid,
                  animationDelay: Duration(milliseconds: 70 * index),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TournamentManagementScreen(tournament: tournament),
                    ),
                  ),
                ),
              );
            }
          }
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: children,
        );
      },
    );
  }

  Widget _buildLocalOnlyList() {
    return const _TournamentEmptyState(
      title: 'Inicia sesión',
      message:
          'Inicia sesión para gestionar tus torneos online o usa la pestaña Locales para organizar competiciones en este dispositivo.',
      icon: Icons.cloud_off_rounded,
    );
  }
}

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

class _RemoteTournamentError extends StatelessWidget {
  const _RemoteTournamentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      'No se pudieron cargar los torneos online: $message',
      style: const TextStyle(color: Colors.white60, fontSize: 12),
    ),
  );
}

class _LocalDraftsHeader extends StatelessWidget {
  const _LocalDraftsHeader({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
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
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
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
                              color: const Color(
                                0xFF00D4FF,
                              ).withValues(alpha: 0.12),
                              border: Border.all(
                                color: const Color(
                                  0xFF00D4FF,
                                ).withValues(alpha: 0.3),
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

class _TournamentListItem extends StatelessWidget {
  const _TournamentListItem({
    required this.tournament,
    required this.currentUid,
    required this.animationDelay,
  });

  final AppTournament tournament;
  final String? currentUid;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    return TournamentCard(
      tournament: tournament,
      isMyTournament: tournament.organizerUid == currentUid,
      animationDelay: animationDelay,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentManagementScreen(tournament: tournament),
        ),
      ),
    );
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
