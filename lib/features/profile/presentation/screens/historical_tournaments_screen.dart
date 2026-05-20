import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../inscription/screen/preinscription_screen.dart';
import '../../../tournament/data/model/enums_tournament.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';
import '../../../user/data/models/user_tournament_history_entry.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../../../user/data/models/public_user_profile.dart';
import 'user_tournament_bracket_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HistoricalTournamentsScreen  ·  Historial completo de torneos
// ─────────────────────────────────────────────────────────────────────────────

class HistoricalTournamentsScreen extends StatefulWidget {
  const HistoricalTournamentsScreen({super.key, required this.uid});

  final String uid;

  @override
  State<HistoricalTournamentsScreen> createState() =>
      _HistoricalTournamentsScreenState();
}

class _HistoricalTournamentsScreenState
    extends State<HistoricalTournamentsScreen>
    with SingleTickerProviderStateMixin {
  late final FirestoreTournamentService _tournamentService;
  late final FirestoreUserService _userService;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;

  PublicUserProfile? _profile;
  bool _profileLoading = true;
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _tournamentService = FirestoreTournamentService();
    _userService = FirestoreUserService();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);

    _loadProfile();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userService.getOtherUserPublicProfile(widget.uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _profileLoading = false;
        });
        _entranceCtrl.forward();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _profileLoading = false);
        _entranceCtrl.forward();
      }
    }
  }

  Future<void> _openTournament(UserTournamentHistoryEntry entry) async {
    if (_openingId != null || entry.tournamentId.isEmpty) return;
    setState(() => _openingId = entry.tournamentId);
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
                targetUid: widget.uid,
                userDisplayName: 'Tú',
              ),
            )
          : MaterialPageRoute(
              builder: (_) => PreinscriptionScreen(tournament: tournament),
            );
      await Navigator.of(context).push(route);
    } catch (_) {
      if (mounted) _showSnack('No se pudo abrir el torneo.');
    } finally {
      if (mounted) setState(() => _openingId = null);
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
          // Backdrop decorativo
          const _Backdrop(),
          SafeArea(
            bottom: false,
            child: _profileLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                      strokeWidth: 2,
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildContent(),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Torneos',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          if (_profile != null && !_profileLoading)
            Text(
              '${_profile!.tournamentHistory.length} torneos registrados',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final history = _profile?.tournamentHistory ?? [];

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _PremiumEmpty(
            icon: Icons.emoji_events_outlined,
            title: 'Aún no hay historial',
            body:
                'Aquí aparecerán los torneos en los que hayas participado y finalizado.',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return _TournamentJourneyCard(
          entry: entry,
          isLoading: _openingId == entry.tournamentId,
          onTap: () => _openTournament(entry),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tarjeta de torneo premium (estilo OtherUserProfileScreen)
// ─────────────────────────────────────────────────────────────────────────────

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
                    // Cover image / placeholder
                    SizedBox(
                      height: 162,
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
                                  : _CoverPlaceholder(
                                      sport: sport,
                                      accent: accent,
                                    ),
                              errorBuilder: (ctx, e, st) =>
                                  _CoverPlaceholder(
                                sport: sport,
                                accent: accent,
                              ),
                            )
                          else
                            _CoverPlaceholder(sport: sport, accent: accent),
                          // Gradient overlay
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.transparent,
                                  const Color(0xFF0A0A1A).withValues(
                                    alpha: 0.92,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Badge deporte
                          Positioned(
                            left: 14,
                            top: 14,
                            child: _GlassBadge(
                              icon: _sportIcon(sport),
                              label: sport.label,
                              color: accent,
                            ),
                          ),
                          // Badge resultado
                          Positioned(
                            right: 14,
                            top: 14,
                            child: _GlassBadge(
                              icon: status.icon,
                              label: status.label,
                              color: status.color,
                            ),
                          ),
                          // Badge campeón
                          if (entry.resultStatus == TournamentResultStatus.won)
                            Positioned(
                              left: 14,
                              bottom: 14,
                              child: _GlassBadge(
                                icon: Icons.workspace_premium_rounded,
                                label: 'Campeón',
                                color: const Color(0xFFFFD166),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Info
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
                              if (entry.tournamentType.contains('private'))
                                _InfoToken(
                                  icon: Icons.lock_outline_rounded,
                                  label: 'Privado',
                                  color: const Color(0xFFB0A8FF),
                                ),
                            ],
                          ),
                          if (isLoading) ...[
                            const SizedBox(height: 14),
                            LinearProgressIndicator(
                              minHeight: 3,
                              color: accent,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
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

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.sport, required this.accent});

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

// ─────────────────────────────────────────────────────────────────────────────
//  Backdrop decorativo
// ─────────────────────────────────────────────────────────────────────────────

class _Backdrop extends StatelessWidget {
  const _Backdrop();

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
              colors: [
                Color(0xFF080817),
                Color(0xFF0C1028),
                Color(0xFF11142F),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -50,
          child: GlowOrb(
            color: const Color(0xFFFFB347).withValues(alpha: 0.18),
            size: 250,
          ),
        ),
        Positioned(
          top: 300,
          left: -100,
          child: GlowOrb(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.14),
            size: 220,
          ),
        ),
        Positioned(
          bottom: -100,
          right: -60,
          child: GlowOrb(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
            size: 200,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

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
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontSize: 10.5,
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
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumEmpty extends StatelessWidget {
  const _PremiumEmpty({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.025),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
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
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper functions
// ─────────────────────────────────────────────────────────────────────────────

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
