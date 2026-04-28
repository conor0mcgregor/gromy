import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:gromy/features/tournament/data/model/app_tournament.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gromy/features/tournament/data/services/location_service.dart';
import 'package:gromy/features/tournament/presentation/controllers/location_picker_controller.dart';
import 'package:gromy/features/tournament/presentation/screens/form/widgets/location_picker_map.dart';
import '../../../inscription/screen/preinscription_screen.dart';
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

  final List<String> _sports = [
    'Fútbol',
    'Baloncesto',
    'Tenis',
    'Pádel',
    'Voleibol',
  ];

  // Filtros avanzados
  DateTimeRange? _filterDateRange;
  LatLng? _filterLocation;
  double? _filterRadiusKm;
  int? _filterParticipants;

  LatLng? get _referencePosition => _filterLocation;

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterBottomSheet(
          availableSports: _sports,
          initialSport: _selectedSport,
          initialDateRange: _filterDateRange,
          initialLocation: _filterLocation,
          initialRadius: _filterRadiusKm,
          initialParticipants: _filterParticipants,
          onApply: (sport, dateRange, locationCoord, radius, participants) {
            setState(() {
              _selectedSport = sport;
              _filterDateRange = dateRange;
              _filterLocation = locationCoord;
              _filterRadiusKm = radius;
              _filterParticipants = participants;
            });
          },
        );
      },
    );
  }

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
    final filtered = all.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.name.toLowerCase().contains(_searchQuery) ||
          t.sport.label.toLowerCase().contains(_searchQuery);

      final matchesSport =
          _selectedSport == null || t.sport.label == _selectedSport || _selectedSport == "";

      final matchesDate = _filterDateRange == null ||
          (t.scheduledAt.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
              t.scheduledAt.isBefore(_filterDateRange!.end.add(const Duration(days: 1))));

      final matchesParticipants = _filterParticipants == null ||
          t.maxParticipants <= _filterParticipants!;

      bool matchesRadius = true;
      if (_referencePosition != null && _filterRadiusKm != null && t.latitude != null && t.longitude != null) {
        final dist = Geolocator.distanceBetween(_referencePosition!.latitude, _referencePosition!.longitude, t.latitude!, t.longitude!) / 1000.0;
        if (dist > _filterRadiusKm!) matchesRadius = false;
      }

      return matchesSearch && matchesSport && matchesDate && matchesParticipants && matchesRadius;
    }).toList();

    // Ordenar por distancia si hay una referencia geográfica disponible
    if (_referencePosition != null) {
      filtered.sort((a, b) {
        if (a.latitude == null || a.longitude == null) return 1;
        if (b.latitude == null || b.longitude == null) return -1;
        final distA = Geolocator.distanceBetween(_referencePosition!.latitude, _referencePosition!.longitude, a.latitude!, a.longitude!);
        final distB = Geolocator.distanceBetween(_referencePosition!.latitude, _referencePosition!.longitude, b.latitude!, b.longitude!);
        return distA.compareTo(distB);
      });
    }

    return filtered;
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

                      // ── Barra de búsqueda y Filtros ──
                      Row(
                        children: [
                          Expanded(child: _SearchBar(controller: _searchController)),
                          const SizedBox(width: 12),
                          _FilterButton(
                            onTap: () => _openFilterSheet(context),
                            isActive: _filterDateRange != null || _filterLocation != null || _filterParticipants != null,
                          ),
                        ],
                      ),
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
                            final t = tournaments[index];
                            double? distanceKm;
                            if (_referencePosition != null && t.latitude != null && t.longitude != null) {
                              distanceKm = Geolocator.distanceBetween(_referencePosition!.latitude, _referencePosition!.longitude, t.latitude!, t.longitude!) / 1000.0;
                            }
                            return TournamentCard(
                              tournament: t,
                              distanceKm: distanceKm,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DemoEnrollScreen(
                                      tournament: t,
                                    ),
                                  ),
                                );
                              },
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

/// Botón para abrir filtros avanzados
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap, required this.isActive});

  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF6C63FF).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: isActive ? const Color(0xFFB0A8FF) : Colors.white.withValues(alpha: 0.4),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Menú inferior (BottomSheet) para filtros avanzados
class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.availableSports,
    required this.initialSport,
    required this.initialDateRange,
    required this.initialLocation,
    required this.initialRadius,
    required this.initialParticipants,
    required this.onApply,
  });

  final List<String> availableSports;
  final String? initialSport;
  final DateTimeRange? initialDateRange;
  final LatLng? initialLocation;
  final double? initialRadius;
  final int? initialParticipants;
  final Function(String?, DateTimeRange?, LatLng?, double?, int?) onApply;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _selectedSportModal;
  DateTimeRange? _selectedDateRange;
  LatLng? _selectedLocation;
  double? _selectedRadiusKm;
  late final TextEditingController _participantsController;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _selectedSportModal = widget.initialSport;
    _selectedDateRange = widget.initialDateRange;
    _selectedLocation = widget.initialLocation;
    _selectedRadiusKm = widget.initialRadius;
    _participantsController = TextEditingController(
      text: widget.initialParticipants?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding para que el teclado no tape el contenido
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF12122E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Filtros Avanzados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Módulo de Deportes
            Text(
              'Deporte',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.availableSports.map((sport) {
                final isSelected = _selectedSportModal == sport;
                return GestureDetector(
                  onTap: () => setState(() {
                    if (_selectedSportModal == sport) {
                      _selectedSportModal = null;
                    } else {
                      _selectedSportModal = sport;
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      sport,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Módulo de Rango de Fechas
            Text(
              'Rango de Fechas',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDateRange == null
                            ? 'Cualquier fecha'
                            : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                    if (_selectedDateRange != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedDateRange = null),
                        child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Módulo de Ubicación Espacial
            Text(
              'Ubicación de Referencia',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (_selectedLocation == null)
              _BottomSheetActionButton(
                icon: Icons.map_rounded,
                label: 'Seleccionar Ubicación',
                onTap: () async {
                  final picked = await Navigator.push<(LatLng, double)?>(context, MaterialPageRoute(builder: (_) => _MapPickerScreen(initialPoint: _selectedLocation, initialRadius: _selectedRadiusKm ?? 10.0)));
                  if (picked != null && mounted) {
                    setState(() {
                      _selectedLocation = picked.$1;
                      _selectedRadiusKm = picked.$2;
                    });
                  }
                },
              )
            else
              GestureDetector(
                onTap: () async {
                  final picked = await Navigator.push<(LatLng, double)?>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => _MapPickerScreen(
                              initialPoint: _selectedLocation,
                              initialRadius: _selectedRadiusKm ?? 10.0
                          )
                      )
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      _selectedLocation = picked.$1;
                      _selectedRadiusKm = picked.$2;
                    });
                  }
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place_rounded, color: Color(0xFFB0A8FF), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Coordenadas guardadas (${_selectedRadiusKm?.toInt()} km)',
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedLocation = null;
                          _selectedRadiusKm = null;
                        }),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Módulo de Participantes
            Text(
              'Límite de participantes (hasta)',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _participantsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ej. 16, 32...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botones Aplicar / Limpiar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedSportModal = null;
                        _selectedDateRange = null;
                        _selectedLocation = null;
                        _selectedRadiusKm = null;
                        _participantsController.clear();
                      });
                      widget.onApply(null, null, null, null, null);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Limpiar', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          _selectedSportModal,
                          _selectedDateRange,
                          _selectedLocation,
                          _selectedRadiusKm,
                          int.tryParse(_participantsController.text.trim()),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Aplicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _BottomSheetActionButton({required this.icon, required this.label, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 18),
            const SizedBox(width: 8),
            Text(isLoading ? '...' : label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _MapPickerScreen extends StatefulWidget {
  const _MapPickerScreen({this.initialPoint, required this.initialRadius});
  final LatLng? initialPoint;
  final double initialRadius;

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  late LocationPickerController _controller;
  late double _radius;
  final List<double> _radiusOptions = [5.0, 10.0, 25.0, 50.0];

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;
    _controller = LocationPickerController(
      initialPoint: widget.initialPoint,
      fallbackCenter: const LatLng(40.4168, -3.7038), // Madrid
      onLocationConfirmed: (_) async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtro de Ubicación', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E1E2C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E1E2C),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LocationPickerMap(
                  controller: _controller,
                  radiusKm: _radius,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF12122E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rango de búsqueda', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _radiusOptions.map((r) {
                      final isSelected = _radius == r;
                      return GestureDetector(
                        onTap: () => setState(() => _radius = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Text('${r.toInt()} km', style: TextStyle(color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_controller.selectedPoint != null) {
                          Navigator.pop(context, (_controller.selectedPoint!, _radius));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un punto en el mapa', style: TextStyle(color: Colors.white))));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}