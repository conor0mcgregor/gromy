import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/icons/my_icons.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../inscription/screen/preinscription_screen.dart';
import '../../../tournament/data/model/enums_tournament.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';
import '../../../user/data/models/public_user_profile.dart';
import '../../../user/data/models/user_profile_stats.dart';
import '../../../user/data/models/user_sport_stats.dart';
import '../../../user/data/models/user_tournament_history_entry.dart';
import '../controllers/other_user_profile_controller.dart';
import 'user_tournament_bracket_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  const OtherUserProfileScreen({super.key, required this.targetUid});

  final String targetUid;

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen>
    with TickerProviderStateMixin {
  static const _historyPageSize = 6;

  late final OtherUserProfileController _controller;
  late final FirestoreTournamentService _tournamentService;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  int _selectedTab = 0;
  int _visibleHistoryCount = _historyPageSize;
  String? _openingTournamentId;

  @override
  void initState() {
    super.initState();
    _controller = OtherUserProfileController(targetUid: widget.targetUid)
      ..addListener(_handleControllerChange)
      ..load();
    _tournamentService = FirestoreTournamentService();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (!_controller.isLoading && _controller.profile != null) {
      _entranceController.forward();
    }
  }

  Future<void> _openTournament(UserTournamentHistoryEntry entry) async {
    if (_openingTournamentId != null || entry.tournamentId.isEmpty) return;

    setState(() => _openingTournamentId = entry.tournamentId);
    try {
      final tournament = await _tournamentService.getTournament(
        entry.tournamentId,
      );
      if (!mounted) return;
      if (tournament == null) {
        _showSnack('No se pudo cargar este torneo.');
        return;
      }

      final route = tournament.status == TournamentStatus.completed
          ? MaterialPageRoute(
              builder: (_) => UserTournamentBracketScreen(
                tournament: tournament,
                targetUid: widget.targetUid,
                userDisplayName: _controller.profile?.user.name ?? 'Jugador',
              ),
            )
          : MaterialPageRoute(
              builder: (_) => PreinscriptionScreen(tournament: tournament),
            );

      await Navigator.of(context).push(route);
    } catch (_) {
      if (mounted) _showSnack('No se pudo abrir el torneo.');
    } finally {
      if (mounted) setState(() => _openingTournamentId = null);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ProfileBackdrop(),
          SafeArea(
            bottom: false,
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const _ProfileLoadingView();
                }

                final profile = _controller.profile;
                if (profile == null || _controller.errorMessage != null) {
                  return _UnavailableView(
                    message:
                        _controller.errorMessage ??
                        'Este perfil es privado o no esta disponible.',
                  );
                }

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _ProfileHero(profile: profile),
                              const SizedBox(height: 18),
                              _SegmentedTabs(
                                selectedIndex: _selectedTab,
                                onChanged: (index) {
                                  setState(() {
                                    _selectedTab = index;
                                    if (index == 1) {
                                      _visibleHistoryCount = _historyPageSize;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 22),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: _selectedTab == 0
                                    ? _SportsStatsSection(profile: profile)
                                    : _TournamentHistorySection(
                                        profile: profile,
                                        visibleCount: _visibleHistoryCount,
                                        openingTournamentId:
                                            _openingTournamentId,
                                        onLoadMore: () {
                                          setState(() {
                                            _visibleHistoryCount +=
                                                _historyPageSize;
                                          });
                                        },
                                        onTournamentTap: _openTournament,
                                      ),
                              ),
                              const SizedBox(height: 32),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: _GlassIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _GlassIconButton(
            icon: Icons.account_tree_rounded,
            onTap: () {
              final profile = _controller.profile;
              final completed = profile?.tournamentHistory.where(
                (entry) =>
                    entry.tournamentStatus == 'completed' ||
                    entry.resultStatus != TournamentResultStatus.pending,
              );
              final entry = completed?.isNotEmpty == true
                  ? completed!.first
                  : null;
              if (entry != null) {
                _openTournament(entry);
              } else {
                _showSnack('Este usuario aun no tiene brackets publicados.');
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF080817), Color(0xFF0C1028), Color(0xFF11142F)],
            ),
          ),
        ),
        Positioned(
          top: -92,
          right: -62,
          child: GlowOrb(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.28),
            size: 280,
          ),
        ),
        Positioned(
          top: 260,
          left: -110,
          child: GlowOrb(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.16),
            size: 230,
          ),
        ),
        Positioned(
          bottom: -120,
          right: -70,
          child: GlowOrb(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.12),
            size: 260,
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final PublicUserProfile profile;

  @override
  Widget build(BuildContext context) {
    final user = profile.user;
    final fullName = '${user.name} ${user.lastName}'.trim();
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final hasPhoto = user.photoUrl != null && user.photoUrl!.trim().isNotEmpty;

    return _GlassPanel(
      padding: EdgeInsets.zero,
      borderRadius: 30,
      child: Stack(
        children: [
          Positioned(
            top: -84,
            right: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00D4FF).withValues(alpha: 0.23),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileAvatar(
                      photoUrl: hasPhoto ? user.photoUrl!.trim() : null,
                      initial: initial,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty ? 'Jugador' : fullName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                height: 1.06,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _SoftChip(
                                  icon: Icons.alternate_email_rounded,
                                  label: user.nickname.isEmpty
                                      ? 'sin-nickname'
                                      : user.nickname,
                                  color: const Color(0xFF00D4FF),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SoftChip(
                  icon: Icons.bolt_rounded,
                  label: _memberSinceLabel(profile.memberSince),
                  color: const Color(0xFFFFB347),
                ),
                if (user.biography != null &&
                    user.biography!.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _BioBlock(text: user.biography!.trim()),
                ],
                const SizedBox(height: 18),
                _QuickStats(stats: profile.stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _memberSinceLabel(DateTime? date) {
    if (date == null) return 'Miembro de Sportiva';

    final now = DateTime.now();
    final months = math.max(
      0,
      (now.year - date.year) * 12 + now.month - date.month,
    );
    if (months >= 12) {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      final yearLabel = years == 1 ? '1 ano' : '$years anos';
      if (remainingMonths == 0) {
        return 'En Sportiva desde hace $yearLabel';
      }
      final monthLabel = remainingMonths == 1
          ? '1 mes'
          : '$remainingMonths meses';
      return 'En Sportiva desde hace $yearLabel y $monthLabel';
    }
    if (months > 0) {
      final monthLabel = months == 1 ? '1 mes' : '$months meses';
      return 'En Sportiva desde hace $monthLabel';
    }

    return 'Miembro desde ${DateFormat('MMMM yyyy', 'es').format(date)}';
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initial, this.photoUrl});

  final String initial;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF), Color(0xFFFF6B9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.36),
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF101127),
            image: photoUrl == null
                ? null
                : DecorationImage(
                    image: NetworkImage(photoUrl!),
                    fit: BoxFit.cover,
                  ),
          ),
          child: photoUrl == null
              ? Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _BioBlock extends StatelessWidget {
  const _BioBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: Color(0xFFB0A8FF),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.stats});

  final UserProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        'Juegos',
        stats.totalPlayed.toString(),
        Icons.sports_score_rounded,
        const Color(0xFF00D4FF),
      ),
      _MetricData(
        'Win rate',
        '${stats.winRate}%',
        Icons.percent_rounded,
        const Color(0xFF22C55E),
      ),
      _MetricData(
        'Victorias',
        stats.wins.toString(),
        Icons.emoji_events_rounded,
        const Color(0xFFFFB347),
      ),
      _MetricData(
        'Torneos',
        stats.tournamentsWon.toString(),
        Icons.workspace_premium_rounded,
        const Color(0xFFA855F7),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: _MetricPill(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.color.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.035),
          ],
        ),
        border: Border.all(color: data.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: data.color.withValues(alpha: 0.13),
            ),
            child: Icon(data.icon, color: data.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
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
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(5),
      borderRadius: 22,
      child: Row(
        children: [
          _TabButton(
            label: 'Estadisticas',
            icon: Icons.auto_graph_rounded,
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _TabButton(
            label: 'Torneos',
            icon: Icons.emoji_events_rounded,
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.26),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportsStatsSection extends StatefulWidget {
  const _SportsStatsSection({required this.profile});

  final PublicUserProfile profile;

  @override
  State<_SportsStatsSection> createState() => _SportsStatsSectionState();
}

class _SportsStatsSectionState extends State<_SportsStatsSection> {
  TournamentSport? _selectedSport;

  @override
  void initState() {
    super.initState();
    _initSelectedSport();
  }
  
  void _initSelectedSport() {
    // Buscar el primer deporte con métricas jugadas
    for (final sport in TournamentSport.values) {
      final stats = widget.profile.sportsStats[sport.name];
      if (stats != null && (stats.matchesPlayed > 0 || stats.totalPlayed > 0)) {
        _selectedSport = sport;
        return;
      }
    }
    // Si no hay ninguno jugado, por defecto el primero
    _selectedSport = TournamentSport.values.first;
  }

  @override
  Widget build(BuildContext context) {
    final availableSports = TournamentSport.values.where((sport) {
      final stats = widget.profile.sportsStats[sport.name];
      return stats != null && (stats.matchesPlayed > 0 || stats.totalPlayed > 0);
    }).toList();
    
    final hasAnyPlayed = availableSports.isNotEmpty;
    // Si no hay ninguno jugado, usamos la lista completa para mostrarlos vacíos
    final displaySports = hasAnyPlayed ? availableSports : TournamentSport.values.toList();
    
    // Fallback si por alguna razón el seleccionado ya no es válido
    if (!displaySports.contains(_selectedSport)) {
      _selectedSport = displaySports.first;
    }

    return Column(
      key: const ValueKey('sports'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: IconPack1.trophy_1,
          title: 'Rendimiento por deporte',
          subtitle: 'Solo metricas clave, sin ruido.',
          color: Color(0xFF00D4FF),
        ),
        const SizedBox(height: 14),
        if (!hasAnyPlayed)
           _GlobalSportEmptyState(color: const Color(0xFF00D4FF))
        else ...[
          // Selector de Deporte
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displaySports.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sport = displaySports[index];
                final isSelected = sport == _selectedSport;
                final accent = sportColor(sport);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSport = sport;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _sportIcon(sport),
                          color: isSelected ? accent : Colors.white.withValues(alpha: 0.5),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sport.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          
          // Tarjeta de estadísticas (Animada)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Builder(
              key: ValueKey(_selectedSport),
              builder: (context) {
                final stats = widget.profile.sportsStats[_selectedSport!.name] ?? UserSportStats.empty;
                return _SportPerformanceCard(sport: _selectedSport!, stats: stats);
              }
            ),
          ),
        ],
      ],
    );
  }
}

class _GlobalSportEmptyState extends StatelessWidget {
  const _GlobalSportEmptyState({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sports_basketball_rounded, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no hay estadísticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El jugador no ha registrado partidos ni torneos en ningún deporte.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SportPerformanceCard extends StatelessWidget {
  const _SportPerformanceCard({required this.sport, required this.stats});

  final TournamentSport sport;
  final UserSportStats stats;

  @override
  Widget build(BuildContext context) {
    final accent = sportColor(sport);
    final hasPlayed = stats.matchesPlayed > 0 || stats.totalPlayed > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _GlassPanel(
        padding: const EdgeInsets.all(16),
        borderRadius: 24,
        glowColor: accent,
        child: Column(
          children: [
            Row(
              children: [
                _SportIcon(sport: sport, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sport.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasPlayed
                            ? '${stats.matchesPlayed} juegos registrados'
                            : 'Aun no ha jugado este deporte',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.48),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _WinRateRing(value: stats.winRate, color: accent),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasPlayed)
              _SportEmptyState(color: accent)
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 2.05,
                children: [
                  _SportMetricTile(
                    label: 'Juegos',
                    value: stats.matchesPlayed.toString(),
                    icon: Icons.sports_score_rounded,
                    color: accent,
                  ),
                  _SportMetricTile(
                    label: 'Win rate',
                    value: '${stats.winRate}%',
                    icon: Icons.percent_rounded,
                    color: const Color(0xFF22C55E),
                  ),
                  _SportMetricTile(
                    label: 'Victorias',
                    value: stats.matchesWon.toString(),
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFFFFB347),
                  ),
                  _SportMetricTile(
                    label: 'Torneos',
                    value: stats.tournamentsWon.toString(),
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFFA855F7),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SportEmptyState extends StatelessWidget {
  const _SportEmptyState({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aun no ha jugado este deporte',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SportMetricTile extends StatelessWidget {
  const _SportMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.47),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WinRateRing extends StatelessWidget {
  const _WinRateRing({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (value / 100).clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return SizedBox(
          width: 58,
          height: 58,
          child: CustomPaint(
            painter: _RingPainter(progress: progress, color: color),
            child: Center(
              child: Text(
                '$value%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..shader = SweepGradient(
        colors: [color, Color.lerp(color, Colors.white, 0.45) ?? color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _TournamentHistorySection extends StatelessWidget {
  const _TournamentHistorySection({
    required this.profile,
    required this.visibleCount,
    required this.openingTournamentId,
    required this.onLoadMore,
    required this.onTournamentTap,
  });

  final PublicUserProfile profile;
  final int visibleCount;
  final String? openingTournamentId;
  final VoidCallback onLoadMore;
  final ValueChanged<UserTournamentHistoryEntry> onTournamentTap;

  @override
  Widget build(BuildContext context) {
    final history = profile.tournamentHistory;
    final visible = history.take(visibleCount).toList();

    return Column(
      key: const ValueKey('history'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.workspace_premium_rounded,
          title: 'Historial de torneos',
          subtitle: 'Portadas, resultado y acceso inteligente.',
          color: Color(0xFFFFB347),
        ),
        const SizedBox(height: 14),
        if (history.isEmpty)
          const _PremiumEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Aun no hay historial de torneos',
            body: 'Cuando participe en eventos, su recorrido aparecera aqui.',
          )
        else ...[
          ...visible.map(
            (entry) => _TournamentJourneyCard(
              entry: entry,
              isLoading: openingTournamentId == entry.tournamentId,
              onTap: () => onTournamentTap(entry),
            ),
          ),
          if (visible.length < history.length) ...[
            const SizedBox(height: 4),
            _LoadMoreButton(
              remaining: history.length - visible.length,
              onTap: onLoadMore,
            ),
          ],
        ],
      ],
    );
  }
}

class _TournamentJourneyCard extends StatelessWidget {
  const _TournamentJourneyCard({
    required this.entry,
    required this.isLoading,
    required this.onTap,
  });

  final UserTournamentHistoryEntry entry;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sport = TournamentSport.fromValue(entry.sport ?? '');
    final accent = sportColor(sport);
    final status = _historyStatus(entry);
    final dateLabel = entry.scheduledAt == null
        ? 'Fecha por confirmar'
        : DateFormat('d MMM yyyy', 'es').format(entry.scheduledAt!);
    final hasCover =
        entry.coverImageUrl != null && entry.coverImageUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedScale(
          scale: isLoading ? 0.985 : 1,
          duration: const Duration(milliseconds: 140),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  color: Colors.white.withValues(alpha: 0.055),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 168,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (hasCover)
                            Image.network(
                              entry.coverImageUrl!.trim(),
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : _TournamentCoverPlaceholder(
                                      sport: sport,
                                      accent: accent,
                                    ),
                              errorBuilder: (context, error, stackTrace) =>
                                  _TournamentCoverPlaceholder(
                                    sport: sport,
                                    accent: accent,
                                  ),
                            )
                          else
                            _TournamentCoverPlaceholder(
                              sport: sport,
                              accent: accent,
                            ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.transparent,
                                  const Color(
                                    0xFF0A0A1A,
                                  ).withValues(alpha: 0.92),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            top: 14,
                            child: _GlassBadge(
                              icon: _sportIcon(sport),
                              label: sport.label,
                              color: accent,
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 14,
                            child: _GlassBadge(
                              icon: status.icon,
                              label: status.label,
                              color: status.color,
                            ),
                          ),
                          if (entry.resultStatus == TournamentResultStatus.won)
                            Positioned(
                              left: 14,
                              bottom: 14,
                              child: _WinnerBadge(
                                color: const Color(0xFFFFD166),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.tournamentName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 9,
                            runSpacing: 9,
                            children: [
                              _InfoToken(
                                icon: Icons.calendar_month_rounded,
                                label: dateLabel,
                              ),
                              _InfoToken(
                                icon: Icons.military_tech_rounded,
                                label: entry.placementLabel.isEmpty
                                    ? status.label
                                    : entry.placementLabel,
                              ),
                              _InfoToken(
                                icon: entry.tournamentStatus == 'completed'
                                    ? Icons.account_tree_rounded
                                    : Icons.open_in_new_rounded,
                                label: entry.tournamentStatus == 'completed'
                                    ? 'Ver recorrido'
                                    : 'Ver detalles',
                                color: accent,
                              ),
                            ],
                          ),
                          if (isLoading) ...[
                            const SizedBox(height: 14),
                            LinearProgressIndicator(
                              minHeight: 3,
                              color: accent,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ],
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

class _TournamentCoverPlaceholder extends StatelessWidget {
  const _TournamentCoverPlaceholder({
    required this.sport,
    required this.accent,
  });

  final TournamentSport sport;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.38),
            const Color(0xFF11142F),
            const Color(0xFF05050E),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -26,
            child: Icon(
              _sportIcon(sport),
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Center(
            child: Icon(
              _sportIcon(sport),
              size: 50,
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.remaining, required this.onTap});

  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        borderRadius: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF00D4FF),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Cargar $remaining torneos mas',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumEmptyState extends StatelessWidget {
  const _PremiumEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(24),
      borderRadius: 26,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withValues(alpha: 0.24),
                  const Color(0xFF00D4FF).withValues(alpha: 0.12),
                ],
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.62),
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _GlassPanel(
            padding: const EdgeInsets.all(20),
            borderRadius: 30,
            child: Column(
              children: [
                Row(
                  children: [
                    const _SkeletonBox(width: 108, height: 108, radius: 54),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _SkeletonBox(width: double.infinity, height: 28),
                          SizedBox(height: 12),
                          _SkeletonBox(width: 150, height: 22),
                          SizedBox(height: 10),
                          _SkeletonBox(width: 190, height: 22),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _SkeletonBox(width: double.infinity, height: 78),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SkeletonBox(width: double.infinity, height: 52),
          const SizedBox(height: 22),
          const _SkeletonBox(width: double.infinity, height: 190),
          const SizedBox(height: 14),
          const _SkeletonBox(width: double.infinity, height: 190),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 18,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.28, end: 0.72),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.045),
                Colors.white.withValues(alpha: value * 0.12),
                Colors.white.withValues(alpha: 0.045),
              ],
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _PremiumEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Perfil no disponible',
          body: message,
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.075),
                Colors.white.withValues(alpha: 0.025),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [
              BoxShadow(
                color: (glowColor ?? const Color(0xFF6C63FF)).withValues(
                  alpha: glowColor == null ? 0.08 : 0.12,
                ),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.07),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SportIcon extends StatelessWidget {
  const _SportIcon({required this.sport, required this.color});

  final TournamentSport sport;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(_sportIcon(sport), color: color, size: 23),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: color.withValues(alpha: 0.16),
            border: Border.all(color: color.withValues(alpha: 0.36)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerBadge extends StatelessWidget {
  const _WinnerBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return _GlassBadge(
      icon: Icons.workspace_premium_rounded,
      label: 'Campeon',
      color: color,
    );
  }
}

class _InfoToken extends StatelessWidget {
  const _InfoToken({
    required this.icon,
    required this.label,
    this.color = const Color(0xFFB0A8FF),
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.055),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _HistoryVisualStatus {
  const _HistoryVisualStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

_HistoryVisualStatus _historyStatus(UserTournamentHistoryEntry entry) {
  return switch (entry.resultStatus) {
    TournamentResultStatus.won => const _HistoryVisualStatus(
      'Ganado',
      Icons.emoji_events_rounded,
      Color(0xFFFFD166),
    ),
    TournamentResultStatus.eliminated => const _HistoryVisualStatus(
      'Eliminado',
      Icons.flag_rounded,
      Color(0xFFFF4D6A),
    ),
    TournamentResultStatus.pending => const _HistoryVisualStatus(
      'En curso',
      Icons.hourglass_top_rounded,
      Color(0xFF00D4FF),
    ),
    TournamentResultStatus.participated => const _HistoryVisualStatus(
      'Participado',
      Icons.check_circle_rounded,
      Color(0xFF6C63FF),
    ),
  };
}

IconData _sportIcon(TournamentSport sport) {
  return switch (sport) {
    TournamentSport.football => Icons.sports_soccer_rounded,
    TournamentSport.basketball => Icons.sports_basketball_rounded,
    TournamentSport.volleyball => Icons.sports_volleyball_rounded,
    TournamentSport.tennis => Icons.sports_tennis_rounded,
    TournamentSport.padel => Icons.sports_tennis_rounded,
    TournamentSport.karate => Icons.sports_martial_arts_rounded,
    TournamentSport.brazilianJiuJitsu => Icons.sports_mma_rounded,
  };
}
