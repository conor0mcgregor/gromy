import 'dart:ui';

import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
//  EXPANDABLE CARD — Widget reutilizable con animación suave
//
//  Uso básico:
//    ExpandableCard(
//      title: 'Información del torneo',
//      icon: Icons.info_outline_rounded,
//      children: [
//        InfoRow(label: 'Nombre', value: 'Liga Primavera 2026'),
//        InfoRow(label: 'Deporte', value: 'Fútbol'),
//      ],
//    )
//
//  Con badge y controlado externamente:
//    ExpandableCard(
//      title: 'Participantes',
//      icon: Icons.groups_2_rounded,
//      badge: '8 / 16',
//      badgeColor: ExpandableBadgeColor.warning,
//      initiallyExpanded: true,
//      children: [...],
//    )
// ════════════════════════════════════════════════════════════════

enum ExpandableBadgeColor { neutral, success, warning, info }

class ExpandableCard extends StatefulWidget {
  const ExpandableCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.badge,
    this.badgeColor = ExpandableBadgeColor.neutral,
    this.initiallyExpanded = false,
    this.accentColor = const Color(0xFF6C63FF),
    this.onExpansionChanged,
  });

  /// Texto principal visible siempre.
  final String title;

  /// Lista de widgets que se muestran al expandir.
  final List<Widget> children;

  /// Icono decorativo a la izquierda del título.
  final IconData? icon;

  /// Texto opcional en un badge a la derecha del título.
  final String? badge;

  /// Color semántico del badge.
  final ExpandableBadgeColor badgeColor;

  /// Si el panel arranca abierto.
  final bool initiallyExpanded;

  /// Color del icono y acento visual al estar abierto.
  final Color accentColor;

  /// Callback cuando cambia el estado (true = abierto).
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  // ── Controlador único: maneja tanto la altura como la flecha ──
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;  // 0 → 1 (altura)
  late final Animation<double> _arrowAnim;   // 0 → 0.5 (rotación = 180°)
  late final Animation<double> _fadeAnim;    // fade del contenido

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );

    _expandAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOutCubic,
    );

    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);

    if (_isExpanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }

    widget.onExpansionChanged?.call(_isExpanded);
  }

  // ──────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.08 + _expandAnim.value * 0.06,
                  ),
                  width: 1.1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header siempre visible ──────────────────
                  _Header(
                    title: widget.title,
                    icon: widget.icon,
                    badge: widget.badge,
                    badgeColor: widget.badgeColor,
                    accentColor: widget.accentColor,
                    arrowAnim: _arrowAnim,
                    expandProgress: _expandAnim.value,
                    onTap: _toggle,
                  ),

                  // ── Cuerpo expandible ───────────────────────
                  SizeTransition(
                    sizeFactor: _expandAnim,
                    axisAlignment: -1,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _Body(children: widget.children),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Header
// ════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.accentColor,
    required this.arrowAnim,
    required this.expandProgress,
    required this.onTap,
  });

  final String title;
  final IconData? icon;
  final String? badge;
  final ExpandableBadgeColor badgeColor;
  final Color accentColor;
  final Animation<double> arrowAnim;
  final double expandProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: accentColor.withValues(alpha: 0.06),
        highlightColor: accentColor.withValues(alpha: 0.03),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icono
              if (icon != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: Color.lerp(
                      Colors.white.withValues(alpha: 0.06),
                      accentColor.withValues(alpha: 0.15),
                      expandProgress,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: Color.lerp(
                      Colors.white.withValues(alpha: 0.5),
                      accentColor,
                      expandProgress,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Título
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.75 + expandProgress * 0.25,
                    ),
                    fontSize: 14.5,
                    fontWeight: expandProgress > 0.5
                        ? FontWeight.w700
                        : FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),

              // Badge
              if (badge != null) ...[
                const SizedBox(width: 8),
                _Badge(text: badge!, color: badgeColor),
              ],

              // Flecha
              const SizedBox(width: 10),
              RotationTransition(
                turns: arrowAnim,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Body
// ════════════════════════════════════════════════════════════════

class _Body extends StatelessWidget {
  const _Body({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divisor superior
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.white.withValues(alpha: 0.07),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Badge
// ════════════════════════════════════════════════════════════════

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final ExpandableBadgeColor color;

  Color get _bg => switch (color) {
    ExpandableBadgeColor.success => const Color(0xFF22C55E).withValues(alpha: 0.15),
    ExpandableBadgeColor.warning => const Color(0xFFFFB347).withValues(alpha: 0.15),
    ExpandableBadgeColor.info    => const Color(0xFF00D4FF).withValues(alpha: 0.15),
    ExpandableBadgeColor.neutral => Colors.white.withValues(alpha: 0.08),
  };

  Color get _fg => switch (color) {
    ExpandableBadgeColor.success => const Color(0xFF22C55E),
    ExpandableBadgeColor.warning => const Color(0xFFFFB347),
    ExpandableBadgeColor.info    => const Color(0xFF00D4FF),
    ExpandableBadgeColor.neutral => Colors.white.withValues(alpha: 0.5),
  };

  Color get _border => _fg.withValues(alpha: 0.3);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: _bg,
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGETS HELPER para el contenido interior
//  (opcionales — puedes pasar cualquier Widget como children)
// ════════════════════════════════════════════════════════════════

/// Fila label / valor con divisor opcional debajo.
class ExpandableInfoRow extends StatelessWidget {
  const ExpandableInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool showDivider;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

/// Barra de progreso con label y porcentaje.
class ExpandableProgressBar extends StatelessWidget {
  const ExpandableProgressBar({
    super.key,
    required this.label,
    required this.value,
    this.color = const Color(0xFF6C63FF),
    this.showDivider = true,
  });

  final String label;

  /// 0.0 a 1.0
  final double value;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${(value.clamp(0.0, 1.0) * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Stack(
                    children: [
                      Container(
                        height: 5,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      FractionallySizedBox(
                        widthFactor: v,
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
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}