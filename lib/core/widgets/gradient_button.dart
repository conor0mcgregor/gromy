import 'package:flutter/material.dart';

import '../getColors/getter_colors.dart';

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
    this.textColor = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final GradientButtonVariant variant;
  final GradientButtonSize size;
  final double width;
  final Color textColor;

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
    GradientButtonSize.small  => const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    GradientButtonSize.medium => const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    GradientButtonSize.large  => const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
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
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: _height),
              child: SizedBox(
                width: widget.width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_borderRadius),
                    gradient: LinearGradient(
                      begin: begin,
                      end: end,
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
              ),  // SizedBox
            ),    // ConstrainedBox
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
              color: widget.textColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                color: widget.textColor.withValues(alpha: 0.8),
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: widget.textColor, size: _iconSize),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              color: widget.textColor,
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              height: 1.35,
            ),
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

