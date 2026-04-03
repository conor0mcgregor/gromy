import 'package:flutter/material.dart';

/// Botón reutilizable con degradado animado y efecto de brillo al pulsar.
///
/// Ejemplo de uso:
/// ```dart
/// GradientButton(
///   label: 'Crear torneo',
///   icon: Icons.emoji_events_rounded,
///   onPressed: () => print('¡Pulsado!'),
/// )
/// ```
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = GradientButtonVariant.violet,
    this.size = GradientButtonSize.medium,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final GradientButtonVariant variant;
  final GradientButtonSize size;
  final double width;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradController;
  late final Animation<double> _gradAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _gradController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _gradAnimation = CurvedAnimation(
      parent: _gradController,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _gradController.dispose();
    super.dispose();
  }

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  double get _height => switch (widget.size) {
    GradientButtonSize.small  => 40,
    GradientButtonSize.medium => 52,
    GradientButtonSize.large  => 60,
  };

  double get _borderRadius => switch (widget.size) {
    GradientButtonSize.small  => 10,
    GradientButtonSize.medium => 14,
    GradientButtonSize.large  => 16,
  };

  double get _fontSize => switch (widget.size) {
    GradientButtonSize.small  => 13,
    GradientButtonSize.medium => 15,
    GradientButtonSize.large  => 17,
  };

  double get _iconSize => switch (widget.size) {
    GradientButtonSize.small  => 15,
    GradientButtonSize.medium => 18,
    GradientButtonSize.large  => 20,
  };

  EdgeInsets get _padding => switch (widget.size) {
    GradientButtonSize.small  => const EdgeInsets.symmetric(horizontal: 20),
    GradientButtonSize.medium => const EdgeInsets.symmetric(horizontal: 28),
    GradientButtonSize.large  => const EdgeInsets.symmetric(horizontal: 36),
  };

  List<Color> get _colors => widget.variant.colors;
  Color get _shadowColor => widget.variant.shadowColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradAnimation,
      builder: (context, child) {
        // Desplazamos el punto de inicio del gradiente en un ciclo 0..1
        final t = _gradAnimation.value;
        final begin = AlignmentTween(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).lerp(t % 1);
        final end = AlignmentTween(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ).lerp(t % 1);

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            if (!_disabled) widget.onPressed!();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: SizedBox(
              width: widget.width,
              height: _height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_borderRadius),
                  gradient: LinearGradient(
                    begin: begin ?? Alignment.topLeft,
                    end: end ?? Alignment.bottomRight,
                    colors: _disabled
                        ? _colors.map((c) => c.withValues(alpha: 0.5)).toList()
                        : _colors,
                  ),
                  boxShadow: _disabled
                      ? []
                      : [
                    BoxShadow(
                      color: _shadowColor.withValues(
                        alpha: _isPressed ? 0.5 : 0.32,
                      ),
                      blurRadius: _isPressed ? 28 : 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(_borderRadius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(_borderRadius),
                    splashColor: Colors.white.withValues(alpha: 0.08),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    onTap: _disabled ? null : widget.onPressed,
                    child: Padding(
                      padding: _padding,
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: Colors.white, size: _iconSize),
          const SizedBox(width: 10),
        ],
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Enums
// ──────────────────────────────────────────────────────────────────────────────

enum GradientButtonSize { small, medium, large }

enum GradientButtonVariant {
  /// Violeta → cian  (por defecto, ideal para acciones principales)
  violet(
    colors: [Color(0xFF6C63FF), Color(0xFFA855F7), Color(0xFF00D4FF)],
    shadowColor: Color(0xFF6C63FF),
  ),

  /// Naranja → rosa → violeta  (energético, CTA destacado)
  sunset(
    colors: [Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF8B5CF6)],
    shadowColor: Color(0xFFEC4899),
  ),

  /// Cian → azul → índigo  (tecnológico, confianza)
  ocean(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF6366F1)],
    shadowColor: Color(0xFF3B82F6),
  ),

  /// Verde esmeralda → lima  (éxito, confirmación)
  forest(
    colors: [Color(0xFF10B981), Color(0xFF22C55E), Color(0xFF84CC16)],
    shadowColor: Color(0xFF10B981),
  );

  const GradientButtonVariant({
    required this.colors,
    required this.shadowColor,
  });

  final List<Color> colors;
  final Color shadowColor;
}