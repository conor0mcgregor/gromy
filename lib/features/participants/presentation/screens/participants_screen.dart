import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/widgets/participant_card.dart';
import '../../../../core/widgets/bar_small_botton.dart';
import '../../data/models/participant_display.dart';
import '../../data/services/participant_display_service.dart';
import '../../../profile/presentation/screens/other_user_profile_screen.dart';
import '../widgets/team_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ParticipantsScreen  ·  Lista completa de participantes de un torneo
//
//  Soporta:
//    - Torneos individuales: lista plana de ParticipantCard
//    - Torneos por equipos: lista de TeamCard expandibles
//    - Con categorías: agrupa participantes por categoría con encabezado
//    - Sin categorías: lista plana
//    - Estado vacío: ilustración + mensaje
// ─────────────────────────────────────────────────────────────────────────────

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isTeamTournament = false,
    this.categories = const [],
  });

  /// ID del torneo en Firestore.
  final String tournamentId;

  /// Nombre del torneo (para el AppBar).
  final String tournamentName;

  /// True si el torneo es por equipos (membersPerTeam > 1).
  final bool isTeamTournament;

  /// Lista de categorías definidas en el torneo (puede estar vacía).
  final List<String> categories;

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen>
    with SingleTickerProviderStateMixin {
  final _service = ParticipantDisplayService();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  late Future<List<ParticipantDisplay>> _future;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _future = _service.getParticipants(widget.tournamentId);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _service.getParticipants(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo degradado ──────────────────────────────────────
          const _Background(),

          // ── Contenido ────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: FutureBuilder<List<ParticipantDisplay>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingView();
                  }

                  if (snapshot.hasError) {
                    return _ErrorView(onRetry: _refresh);
                  }

                  final participants = snapshot.data ?? [];

                  if (participants.isEmpty) {
                    return _EmptyView(
                      isTeamTournament: widget.isTeamTournament,
                    );
                  }

                  return _ParticipantsList(
                    participants: participants,
                    isTeamTournament: widget.isTeamTournament,
                    categories: widget.categories,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            backgroundColor: const Color(0xFF0A0A1A).withValues(alpha: 0.7),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: BarSmallBotton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Participantes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  widget.tournamentName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Lista de participantes (con soporte para categorías)
// ─────────────────────────────────────────────────────────────────────────────

class _ParticipantsList extends StatelessWidget {
  const _ParticipantsList({
    required this.participants,
    required this.isTeamTournament,
    required this.categories,
  });

  final List<ParticipantDisplay> participants;
  final bool isTeamTournament;
  final List<String> categories;

  bool get _hasCategories => categories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasCategories) {
      return _GroupedList(
        participants: participants,
        categories: categories,
        isTeamTournament: isTeamTournament,
      );
    }

    return _FlatList(
      participants: participants,
      isTeamTournament: isTeamTournament,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Lista plana (sin categorías)
// ─────────────────────────────────────────────────────────────────────────────

class _FlatList extends StatelessWidget {
  const _FlatList({
    required this.participants,
    required this.isTeamTournament,
  });

  final List<ParticipantDisplay> participants;
  final bool isTeamTournament;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: participants.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _ParticipantItem(
          participant: participants[index],
          isTeamTournament: isTeamTournament,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Lista agrupada por categorías
// ─────────────────────────────────────────────────────────────────────────────

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.participants,
    required this.categories,
    required this.isTeamTournament,
  });

  final List<ParticipantDisplay> participants;
  final List<String> categories;
  final bool isTeamTournament;

  Map<String, List<ParticipantDisplay>> _groupByCategory() {
    final grouped = <String, List<ParticipantDisplay>>{};

    for (final p in participants) {
      final key = p.categoryId ?? _kSinCategoria;
      grouped.putIfAbsent(key, () => []).add(p);
    }
    return grouped;
  }

  static const String _kSinCategoria = '__sin_categoria__';

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory();

    // Orden: categorías definidas primero, luego "sin categoría"
    final orderedKeys = [
      ...categories.where(grouped.containsKey),
      if (grouped.containsKey(_kSinCategoria)) _kSinCategoria,
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: orderedKeys.length,
      itemBuilder: (context, sectionIndex) {
        final key = orderedKeys[sectionIndex];
        final items = grouped[key]!;
        final label = key == _kSinCategoria ? 'Sin categoría' : key;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionIndex > 0) const SizedBox(height: 24),

            // ── Encabezado de categoría ──────────────────────────
            _CategoryHeader(label: label, count: items.length),
            const SizedBox(height: 12),

            // ── Participantes de la categoría ────────────────────
            ...List.generate(items.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ParticipantItem(
                  participant: items[i],
                  isTeamTournament: isTeamTournament,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Encabezado de categoría
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Item individual: usuario o equipo según el tipo
// ─────────────────────────────────────────────────────────────────────────────

class _ParticipantItem extends StatelessWidget {
  const _ParticipantItem({
    required this.participant,
    required this.isTeamTournament,
  });

  final ParticipantDisplay participant;
  final bool isTeamTournament;

  @override
  Widget build(BuildContext context) {
    return switch (participant) {
      UserParticipantDisplay(:final user) => ParticipantCard(
        nickname: user.nickname,
        displayName: '${user.name} ${user.lastName}'.trim(),
        photoUrl: user.photoUrl,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtherUserProfileScreen(targetUid: user.uid),
            ),
          );
        },
      ),
      TeamParticipantDisplay(:final team) => TeamCard(team: team),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Estados de la pantalla
// ─────────────────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A1A),
            Color(0xFF0D0D2B),
            Color(0xFF12122E),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando participantes…',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isTeamTournament});

  final bool isTeamTournament;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                isTeamTournament
                    ? Icons.groups_2_outlined
                    : Icons.person_search_rounded,
                size: 36,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isTeamTournament
                  ? 'Aún no hay equipos inscritos'
                  : 'Aún no hay participantes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '¡Sé el primero en unirte a este torneo!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar la lista',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
