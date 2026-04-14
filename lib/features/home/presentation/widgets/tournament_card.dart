import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/imagen_frame.dart';
import '../../../tournament/data/model/app_tournament.dart';

// ════════════════════════════════════════════════════════════════
//  TOURNAMENT CARD
// ════════════════════════════════════════════════════════════════

class TournamentCard extends StatefulWidget {
  const TournamentCard({
    super.key,
    required this.tournament,
    this.animationDelay = Duration.zero,
    this.onTap,
    this.isMyTournament
  });

  final AppTournament tournament;

  /// Retraso de entrada escalonado para la lista (p. ej. 100 ms × índice).
  final Duration animationDelay;

  final VoidCallback? onTap;

  final bool? isMyTournament;

  @override
  State<TournamentCard> createState() => _TournamentCardState();
}

class _TournamentCardState extends State<TournamentCard>
    with TickerProviderStateMixin {
  // ── Animación de entrada ──
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── Animación de shimmer en el badge del deporte ──
  late final AnimationController _shimmerCtrl;

  // ── Animación de pulsación al tocar ──
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Entrada
    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    ));

    // Shimmer
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    // Pulsación
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );

    // Dispara la entrada con el delay escalonado
    Future.delayed(widget.animationDelay, () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _shimmerCtrl.dispose();
    _pressCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  //  Helpers de estado
  // ──────────────────────────────────────────────────────────────

  double get _occupancy =>
      widget.tournament.maxParticipants > 0
          ? widget.tournament.participantCount /
          widget.tournament.maxParticipants
          : 0;

  String get _occupancyLabel {
    if (_occupancy >= 0.8) return 'Casi lleno';
    if (_occupancy >= 0.6) return 'Bastantes plazas';
    return 'Plazas disponibles';
  }

  Color get _sportAccent => sportColor(widget.tournament.sport);

  // ──────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dateStr =
    DateFormat('dd MMM, yyyy', 'es').format(widget.tournament.scheduledAt);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _pressCtrl.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _pressCtrl.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _pressCtrl.reverse();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white
                              .withValues(alpha: _isPressed ? 0.1 : 0.07),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: _isPressed ? 0.18 : 0.1),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _sportAccent
                              .withValues(alpha: _isPressed ? 0.18 : 0.08),
                          blurRadius: _isPressed ? 28 : 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // ── Acento izquierdo de color por deporte ──

                        // ── Orbe de brillo difuso en esquina ──
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _sportAccent.withValues(alpha: 0.12),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Contenido ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ImageFrame(
                                coverUrl: widget.tournament.portadaUrl,
                                accent: _sportAccent,
                              ),
                              const SizedBox(height: 16),

                              //labels
                              Padding(
                                padding: const EdgeInsets.all(0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _AnimatedSportBadge(
                                      label: widget.tournament.sport.label
                                          .toUpperCase(),
                                      color: _sportAccent,
                                      shimmerCtrl: _shimmerCtrl,
                                    ),
                                    _ParticipantsBadge(
                                      current: widget.tournament.participantCount,
                                      max: widget.tournament.maxParticipants,
                                      occupancyColor: occupancyColor(_occupancy),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (widget.isMyTournament == true) Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.06),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user_outlined,
                                      color: Color(0xFFB0A8FF), size: 16),
                                  const SizedBox(width: 8),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 200),
                                    child: Text(
                                      "Creador",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),


                              const SizedBox(height: 16),


                              // Nombre
                              Text(
                                widget.tournament.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 7),

                              // Descripción
                              Text(
                                widget.tournament.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13.5,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Barra de ocupación
                              _OccupancyBar(
                                occupancy: _occupancy,
                                color: occupancyColor(_occupancy),
                                label: _occupancyLabel,
                                current: widget.tournament.participantCount,
                                max: widget.tournament.maxParticipants,
                              ),
                              const SizedBox(height: 16),

                              // Divisor
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Fecha + lugar + flecha
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // Optional: aligns the wrap to the left
                                children: [
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    children: [
                                      _InfoChip(
                                        icon: Icons.calendar_month_rounded,
                                        label: dateStr,
                                      ),
                                      _InfoChip(
                                        icon: Icons.location_on_rounded,
                                        label: widget.tournament.location,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  SUB-WIDGETS DE LA CARD
// ════════════════════════════════════════════════════════════════

/// Badge del deporte con shimmer animado
class _AnimatedSportBadge extends StatelessWidget {
  const _AnimatedSportBadge({
    required this.label,
    required this.color,
    required this.shimmerCtrl,
  });

  final String label;
  final Color color;
  final AnimationController shimmerCtrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerCtrl,
      builder: (context, child) {
        // El shimmer desplaza un degradado de izquierda a derecha
        final shimmerX = (shimmerCtrl.value * 2 - 0.5) * 200;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                color,
                Color.lerp(color, Colors.white, 0.7) ?? color,
                color,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(
                  (shimmerX / bounds.width).clamp(-1.0, 1.0) - 0.5, 0),
              end: Alignment(
                  (shimmerX / bounds.width).clamp(-1.0, 1.0) + 0.5, 0),
            ).createShader(bounds),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Badge de participantes con punto de color
class _ParticipantsBadge extends StatelessWidget {
  const _ParticipantsBadge({
    required this.current,
    required this.max,
    required this.occupancyColor,
  });

  final int current;
  final int max;
  final Color occupancyColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.1), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Punto de color (estado de ocupación)
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: occupancyColor,
              boxShadow: [
                BoxShadow(
                  color: occupancyColor.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Icon(Icons.people_alt_rounded,
              size: 13, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            '$current/$max',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de ocupación con label y animación
class _OccupancyBar extends StatelessWidget {
  const _OccupancyBar({
    required this.occupancy,
    required this.color,
    required this.label,
    required this.current,
    required this.max,
  });

  final double occupancy;
  final Color color;
  final String label;
  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.5), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            Text(
              '${(occupancy * 100).round()}% ocupado',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: occupancy.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Stack(
                children: [
                  // Fondo
                  Container(
                    height: 5,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  // Relleno
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.7),
                            color,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Chip de información (fecha / lugar)
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.maxWidth,
  });

  final IconData icon;
  final String label;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    Widget text = Text(
      label,
      overflow: maxWidth != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
    );

    if (maxWidth != null) {
      text = SizedBox(width: maxWidth, child: text);
    }

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
          ),
          child: Icon(icon, size: 13, color: const Color(0xFF00D4FF)),
        ),
        const SizedBox(width: 7),
        Expanded(child: text)
      ],
    );
  }
}
