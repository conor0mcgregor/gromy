import 'dart:ui';
import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
//  GLASS TAB BAR — versión mejorada
//
//  Uso:
//    TabBar con DefaultTabController o TabController propio.
//    Pasa una lista de GlassTab en vez de Tab estándar.
//
//  Ejemplo:
//    GlassTabBar(
//      controller: _tabController,
//      tabs: const [
//        GlassTab(label: 'Torneos',  icon: Icons.emoji_events_rounded),
//        GlassTab(label: 'Mis retos', icon: Icons.sports_rounded),
//        GlassTab(label: 'Perfil',   icon: Icons.person_rounded),
//      ],
//    )
// ════════════════════════════════════════════════════════════════

class GlassTabBar extends StatefulWidget implements PreferredSizeWidget {
  const GlassTabBar({
    super.key,
    required this.tabs,
    this.controller,
    /// Colores del degradado del indicador activo.
    this.gradientColors = const [Color(0xFF6C63FF), Color(0xFF00D4FF)],
    this.height = 58,
  });

  final List<GlassTab> tabs;
  final TabController? controller;
  final List<Color> gradientColors;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height + 12); // +padding

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar>
    with TickerProviderStateMixin {
  // Shimmer sobre el indicador activo
  late final AnimationController _shimmerCtrl;

  TabController? _internalCtrl;
  TabController? _effectiveCtrl;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newCtrl = widget.controller ?? DefaultTabController.maybeOf(context);
    
    if (newCtrl == null) {
      _internalCtrl ??= TabController(length: widget.tabs.length, vsync: this);
      _updateController(_internalCtrl);
    } else {
      _internalCtrl?.dispose();
      _internalCtrl = null;
      _updateController(newCtrl);
    }
  }

  void _updateController(TabController? newCtrl) {
    if (_effectiveCtrl == newCtrl) return;
    _effectiveCtrl?.removeListener(_onTabChanged);
    _effectiveCtrl = newCtrl;
    _effectiveCtrl?.addListener(_onTabChanged);
    _previousIndex = _effectiveCtrl?.index ?? 0;
  }

  void _onTabChanged() {
    if (_effectiveCtrl != null && _effectiveCtrl!.index != _previousIndex) {
      setState(() => _previousIndex = _effectiveCtrl!.index);
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _effectiveCtrl?.removeListener(_onTabChanged);
    _internalCtrl?.dispose();
    super.dispose();
  }

  Color get _shadowColor => widget.gradientColors.first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.2,
              ),
            ),
            child: TabBar(
              controller: _effectiveCtrl,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
              labelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: EdgeInsets.zero,
              // Indicador con shimmer animado
              indicator: _ShimmerIndicator(
                shimmerCtrl: _shimmerCtrl,
                gradientColors: widget.gradientColors,
                shadowColor: _shadowColor,
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: List.generate(widget.tabs.length, (i) {
                return _AnimatedTabItem(
                  tab: widget.tabs[i],
                  isSelected: _effectiveCtrl?.index == i,
                  activeColor: widget.gradientColors.first,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  INDICADOR CON SHIMMER
// ════════════════════════════════════════════════════════════════

class _ShimmerIndicator extends Decoration {
  const _ShimmerIndicator({
    required this.shimmerCtrl,
    required this.gradientColors,
    required this.shadowColor,
    required this.borderRadius,
  });

  final AnimationController shimmerCtrl;
  final List<Color> gradientColors;
  final Color shadowColor;
  final BorderRadius borderRadius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _ShimmerPainter(
      shimmerCtrl: shimmerCtrl,
      gradientColors: gradientColors,
      shadowColor: shadowColor,
      borderRadius: borderRadius,
      onChanged: onChanged,
    );
  }
}

class _ShimmerPainter extends BoxPainter {
  _ShimmerPainter({
    required this.shimmerCtrl,
    required this.gradientColors,
    required this.shadowColor,
    required this.borderRadius,
    VoidCallback? onChanged,
  }) : super(onChanged) {
    _listener = () => onChanged?.call();
    shimmerCtrl.addListener(_listener);
  }

  late final VoidCallback _listener;
  final AnimationController shimmerCtrl;
  final List<Color> gradientColors;
  final Color shadowColor;
  final BorderRadius borderRadius;

  @override
  void dispose() {
    shimmerCtrl.removeListener(_listener);
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    final rect = offset & (config.size ?? Size.zero);
    final rrect = borderRadius.toRRect(rect);

    // ── Sombra con glow ──
    final shadowPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.translate(0, 5),
        const Radius.circular(14),
      ),
      shadowPaint,
    );

    // ── Degradado base ──
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect);
    canvas.drawRRect(rrect, basePaint);

    // ── Shimmer sweeping light ──
    final t = shimmerCtrl.value;
    final shimmerX = rect.left + rect.width * (t * 1.8 - 0.4);
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(
        shimmerX - 40,
        rect.top,
        80,
        rect.height,
      ));
    canvas.drawRRect(rrect, shimmerPaint);

    // ── Borde sutil superior (lustre) ──
    final lustrePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, lustrePaint);
  }
}

// ════════════════════════════════════════════════════════════════
//  ITEM DE TAB CON ANIMACIÓN
// ════════════════════════════════════════════════════════════════

class _AnimatedTabItem extends StatelessWidget {
  const _AnimatedTabItem({
    required this.tab,
    required this.isSelected,
    required this.activeColor,
  });

  final GlassTab tab;
  final bool isSelected;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono (si existe)
            if (tab.icon != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: isSelected ? 22 : 20,
                height: isSelected ? 22 : 20,
                child: Icon(
                  tab.icon,
                  size: isSelected ? 18 : 16,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 6),
            ],

            // Texto
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: isSelected ? 13 : 12.5,
                  fontWeight:
                  isSelected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: isSelected ? 0.1 : 0,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  overflow: TextOverflow.ellipsis,
                ),
                child: Text(tab.label, maxLines: 1),
              ),
            ),

            // Punto indicador de notificación (opcional)
            if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
              const SizedBox(width: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: tab.badgeCount! > 9 ? 18 : 14,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFFF4D6A),
                ),
                child: Center(
                  child: Text(
                    tab.badgeCount! > 9 ? '9+' : '${tab.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  MODELO DE TAB
// ════════════════════════════════════════════════════════════════

/// Define cada pestaña de [GlassTabBar].
class GlassTab {
  const GlassTab({
    required this.label,
    this.icon,
    this.badgeCount,
  });

  final String label;
  final IconData? icon;

  /// Si no es null y > 0, muestra un badge numérico rojo en la pestaña.
  final int? badgeCount;
}