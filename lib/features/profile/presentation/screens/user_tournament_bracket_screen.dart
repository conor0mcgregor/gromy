import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../brackets/data/models/app_match.dart';
import '../../../brackets/presentation/controllers/bracket_controller.dart';
import '../../../brackets/presentation/screens/bracket_screen.dart';
import '../../../tournament/data/model/app_tournament.dart';

class UserTournamentBracketScreen extends StatefulWidget {
  const UserTournamentBracketScreen({
    super.key,
    required this.tournament,
    required this.targetUid,
    required this.userDisplayName,
  });

  final AppTournament tournament;
  final String targetUid;
  final String userDisplayName;

  @override
  State<UserTournamentBracketScreen> createState() =>
      _UserTournamentBracketScreenState();
}

class _UserTournamentBracketScreenState
    extends State<UserTournamentBracketScreen> {
  late final BracketController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BracketController(tournamentId: widget.tournament.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = sportColor(widget.tournament.sport);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: _RoundGlassIcon(icon: Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: _RoundGlassIcon(icon: Icons.open_in_full_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BracketScreen(
                    tournamentId: widget.tournament.id,
                    isAdmin: false,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Backdrop(accent: accent),
          SafeArea(
            bottom: false,
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _JourneyHero(
                            tournament: widget.tournament,
                            userDisplayName: widget.userDisplayName,
                            accent: accent,
                          ),
                          const SizedBox(height: 18),
                          _buildBody(accent),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Color accent) {
    return switch (_controller.state) {
      BracketViewState.loading => _GlassPanel(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Center(child: CircularProgressIndicator(color: accent)),
        ),
      ),
      BracketViewState.empty => const _EmptyJourney(
        title: 'Bracket no publicado',
        body: 'Este torneo todavia no tiene un bracket visible.',
      ),
      BracketViewState.error => _EmptyJourney(
        title: 'No se pudo cargar',
        body: _controller.errorMessage ?? 'Error desconocido.',
      ),
      BracketViewState.loaded => _LoadedJourney(
        controller: _controller,
        targetUid: widget.targetUid,
        userDisplayName: widget.userDisplayName,
        accent: accent,
      ),
    };
  }
}

class _LoadedJourney extends StatelessWidget {
  const _LoadedJourney({
    required this.controller,
    required this.targetUid,
    required this.userDisplayName,
    required this.accent,
  });

  final BracketController controller;
  final String targetUid;
  final String userDisplayName;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bracket = controller.selectedBracket;
    final matches =
        controller.matches
            .where((match) => _containsUser(match, targetUid))
            .toList()
          ..sort((a, b) {
            final roundCompare = a.round.compareTo(b.round);
            if (roundCompare != 0) return roundCompare;
            return a.matchOrder.compareTo(b.matchOrder);
          });

    if (matches.isEmpty) {
      return Column(
        children: [
          _CategoryChips(controller: controller),
          const SizedBox(height: 14),
          const _EmptyJourney(
            title: 'Sin recorrido encontrado',
            body:
                'No encontramos enfrentamientos vinculados a este usuario en la categoria seleccionada.',
          ),
        ],
      );
    }

    final wins = matches.where((m) => m.winnerId == targetUid).length;
    final losses = matches.where((m) => m.loserId == targetUid).length;
    final reached = controller.roundName(
      matches.map((m) => m.round).reduce((a, b) => a > b ? a : b),
      bracket?.totalRounds ?? 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryChips(controller: controller),
        const SizedBox(height: 14),
        _PerformanceSummary(
          matches: matches.length,
          wins: wins,
          losses: losses,
          reached: reached,
          accent: accent,
        ),
        const SizedBox(height: 18),
        _SectionLabel(
          icon: Icons.route_rounded,
          title: 'Recorrido de $userDisplayName',
          color: accent,
        ),
        const SizedBox(height: 12),
        ...matches.map(
          (match) => _MatchJourneyCard(
            match: match,
            targetUid: targetUid,
            roundName: controller.roundName(
              match.round,
              bracket?.totalRounds ?? 0,
            ),
            accent: accent,
          ),
        ),
      ],
    );
  }

  bool _containsUser(AppMatch match, String uid) {
    return match.participant1Id == uid ||
        match.participant2Id == uid ||
        match.participant1MemberIds.contains(uid) ||
        match.participant2MemberIds.contains(uid);
  }
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({
    required this.tournament,
    required this.userDisplayName,
    required this.accent,
  });

  final AppTournament tournament;
  final String userDisplayName;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy', 'es').format(tournament.scheduledAt);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        height: 238,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tournament.portadaUrl != null &&
                tournament.portadaUrl!.trim().isNotEmpty)
              Image.network(
                tournament.portadaUrl!.trim(),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) =>
                    _CoverFallback(accent: accent),
              )
            else
              _CoverFallback(accent: accent),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.24),
                    Colors.transparent,
                    const Color(0xFF0A0A1A).withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassBadge(
                    icon: Icons.account_tree_rounded,
                    label: 'Recorrido en bracket',
                    color: accent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tournament.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        icon: Icons.person_rounded,
                        label: userDisplayName,
                      ),
                      _InfoPill(
                        icon: Icons.calendar_month_rounded,
                        label: date,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});

  final BracketController controller;

  @override
  Widget build(BuildContext context) {
    final categories = controller.availableCategories;
    if (categories.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = controller.selectedBracket?.categoryName == category;
          return GestureDetector(
            onTap: () => controller.selectCategory(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: selected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withValues(alpha: 0.055),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.09),
                ),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}

class _PerformanceSummary extends StatelessWidget {
  const _PerformanceSummary({
    required this.matches,
    required this.wins,
    required this.losses,
    required this.reached,
    required this.accent,
  });

  final int matches;
  final int wins;
  final int losses;
  final String reached;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.auto_graph_rounded,
            title: 'Desempeno',
            color: accent,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Juegos',
                  value: '$matches',
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Victorias',
                  value: '$wins',
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Derrotas',
                  value: '$losses',
                  color: const Color(0xFFFF4D6A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryTile(
            label: 'Alcanzo',
            value: reached,
            color: const Color(0xFFFFB347),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchJourneyCard extends StatelessWidget {
  const _MatchJourneyCard({
    required this.match,
    required this.targetUid,
    required this.roundName,
    required this.accent,
  });

  final AppMatch match;
  final String targetUid;
  final String roundName;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final userIsP1 =
        match.participant1Id == targetUid ||
        match.participant1MemberIds.contains(targetUid);
    final userName = userIsP1
        ? (match.participant1Name ?? 'Jugador')
        : (match.participant2Name ?? 'Jugador');
    final rivalName = userIsP1
        ? (match.participant2Name ?? 'Rival por confirmar')
        : (match.participant1Name ?? 'Rival por confirmar');
    final won =
        match.winnerId == targetUid ||
        (userIsP1 && match.participant1Id == match.winnerId) ||
        (!userIsP1 && match.participant2Id == match.winnerId);
    final lost =
        match.loserId == targetUid ||
        (userIsP1 && match.participant1Id == match.loserId) ||
        (!userIsP1 && match.participant2Id == match.loserId);
    final color = won
        ? const Color(0xFF22C55E)
        : lost
        ? const Color(0xFFFF4D6A)
        : accent;
    final result = won
        ? 'Victoria'
        : lost
        ? 'Derrota'
        : match.status.label;

    final scoreA = match.scoreParticipant1;
    final scoreB = match.scoreParticipant2;
    final score = scoreA != null && scoreB != null ? '$scoreA - $scoreB' : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassPanel(
        glowColor: color,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withValues(alpha: 0.13),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(
                won
                    ? Icons.check_rounded
                    : lost
                    ? Icons.close_rounded
                    : Icons.schedule_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roundName,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'vs $rivalName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  result,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (score != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    score,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyJourney extends StatelessWidget {
  const _EmptyJourney({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 46,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 14),
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
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.34),
            const Color(0xFF12122E),
            const Color(0xFF05050E),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.account_tree_rounded,
          size: 74,
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
            border: Border.all(color: color.withValues(alpha: 0.34)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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

class _RoundGlassIcon extends StatelessWidget {
  const _RoundGlassIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.glowColor});

  final Widget child;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.055),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [
              BoxShadow(
                color: (glowColor ?? const Color(0xFF6C63FF)).withValues(
                  alpha: 0.09,
                ),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.accent});

  final Color accent;

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
              colors: [Color(0xFF080817), Color(0xFF0F172A), Color(0xFF11142F)],
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -70,
          child: GlowOrb(color: accent.withValues(alpha: 0.25), size: 270),
        ),
        Positioned(
          bottom: -110,
          left: -80,
          child: GlowOrb(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.14),
            size: 250,
          ),
        ),
      ],
    );
  }
}
