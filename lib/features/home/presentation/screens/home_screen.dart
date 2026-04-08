import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:gromy/features/tournament/data/model/app_tournament.dart';
import '../controllers/home_controller.dart';
import '../widgets/tournament_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final HomeController _homeController;

  // ── Animación de entrada del header ──
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  // ── Búsqueda y filtros ──
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSport; // null = todos

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();

    _headerCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _headerCtrl, curve: Curves.easeOutCubic));

    _headerCtrl.forward();

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AppTournament> _filter(List<AppTournament> all) {
    return all.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.name.toLowerCase().contains(_searchQuery) ||
          t.location.toLowerCase().contains(_searchQuery) ||
          t.sport.label.toLowerCase().contains(_searchQuery);
      final matchesSport =
          _selectedSport == null || t.sport.label == _selectedSport || _selectedSport == "";
      return matchesSearch && matchesSport;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header animado ──
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saludo + avatar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              ShaderMask(
                                shaderCallback: (b) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFB0A8FF),
                                      ],
                                    ).createShader(b),
                                child: const Text(
                                  'Explorar torneos',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Botón de notificaciones
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Encuentra y únete a los mejores eventos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Barra de búsqueda ──
                      _SearchBar(controller: _searchController),
                    ],
                  ),
                ),
              ),
            ),

            // ── Chips de filtro de deporte ──
            StreamBuilder<List<AppTournament>>(
              stream: _homeController.watchTournaments(),
              builder: (context, snapshot) {
                final all = snapshot.data ?? [];
                final sports = all.map((t) => t.sport.label).toSet().toList()
                  ..sort();

                if (sports.isEmpty) return const SizedBox(height: 16);

                return FadeTransition(
                  opacity: _headerFade,
                  child: _SportFilterRow(
                    sports: sports,
                    selected: _selectedSport,
                    onSelect: (s) =>
                        setState(() => _selectedSport = _selectedSport == s ? null : s),
                  ),
                );
              },
            ),

            // ── Lista de torneos ──
            Expanded(
              child: StreamBuilder<List<AppTournament>>(
                stream: _homeController.watchTournaments(),
                builder: (context, snapshot) {
                  // Cargando
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingState();
                  }

                  // Error
                  if (snapshot.hasError) {
                    return _ErrorState(message: '${snapshot.error}');
                  }

                  final all = snapshot.data ?? [];
                  final tournaments = _filter(all);

                  // Vacío
                  if (tournaments.isEmpty) {
                    return _EmptyState(isFiltered: all.isNotEmpty);
                  }

                  // Contador + lista
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                        child: Text(
                          '${tournaments.length} torneo${tournaments.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: tournaments.length,
                          itemBuilder: (context, index) {
                            return TournamentCard(
                              tournament: tournaments[index],
                              // Entrada escalonada: cada card aparece 80ms después
                              animationDelay:
                              Duration(milliseconds: 80 * index),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  SUB-WIDGETS DEL HOME
// ════════════════════════════════════════════════════════════════

/// Barra de búsqueda con glassmorphism
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Buscar torneos, deportes, lugares...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
              prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
              suffixIcon: ValueListenableBuilder(
                valueListenable: controller,
                builder: (_, value, __) => value.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 18),
                  onPressed: controller.clear,
                )
                    : const SizedBox.shrink(),
              ),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de chips de filtro por deporte
class _SportFilterRow extends StatelessWidget {
  const _SportFilterRow({
    required this.sports,
    required this.selected,
    required this.onSelect,
  });

  final List<String> sports;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        scrollDirection: Axis.horizontal,
        children: [
          // "Todos"
          _FilterChip(
            label: 'Todos',
            selected: selected == null,
            onTap: () => onSelect(''), // el padre lo maneja con toggle
          ),
          const SizedBox(width: 8),
          ...sports.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: s,
              selected: selected == s,
              onTap: () => onSelect(s),
            ),
          )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected
              ? const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)])
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Estado de carga con shimmer skeleton
class _LoadingState extends StatefulWidget {
  const _LoadingState();

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: 4,
      itemBuilder: (_, i) => _SkeletonCard(anim: _anim, delay: i * 0.15),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.anim, required this.delay});

  final Animation<double> anim;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final shimmer =
        ((anim.value + delay) % 1.0);
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: shimmer * 0.08 + 0.02),
                Colors.white.withValues(alpha: 0.04),
              ],
              stops: [
                (shimmer - 0.3).clamp(0, 1),
                shimmer.clamp(0, 1),
                (shimmer + 0.3).clamp(0, 1),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        );
      },
    );
  }
}

/// Estado vacío (sin torneos o sin resultados de búsqueda)
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFiltered});

  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  const Color(0xFF00D4FF).withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.emoji_events_outlined,
              size: 40,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isFiltered ? 'Sin resultados' : 'Aún no hay torneos',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Prueba con otro deporte o término de búsqueda.'
                : 'Crea el primero y empieza a competir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de error
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: const Color(0xFFFF4D6A).withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              'Algo salió mal',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Comprueba tu conexión e inténtalo de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}