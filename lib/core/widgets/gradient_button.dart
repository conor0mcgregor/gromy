import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../getColors/getter_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnimationType  –  define el comportamiento visual del botón
// ─────────────────────────────────────────────────────────────────────────────

/// Tipos de animación disponibles para [GradientButton].
///
/// | Valor            | Descripción                                             |
/// |------------------|---------------------------------------------------------|
/// | `gradientShift`  | **Por defecto.** Gradiente que rota en bucle suave.     |
/// | `none`           | Sin animación. Degradado estático.                      |
/// | `subtle`         | Pulso de opacidad/escala muy leve y continuo.           |
/// | `pulse`          | Latido (scale + sombra) marcado en bucle.               |
/// | `shimmer`        | Destello de luz que barre el botón de izquierda a       |
/// |                  | derecha en bucle.                                       |
/// | `breathe`        | Expansión/contracción de sombra y brillo, efecto        |
/// |                  | respiración lenta.                                      |
enum AnimationType {
  /// Gradiente animado que rota continuamente. **Valor por defecto.**
  gradientShift,

  /// Sin animación. El degradado es estático.
  none,

  /// Pulso de escala/opacidad muy sutil y continuo.
  subtle,

  /// Latido marcado: la escala y la sombra se expanden y contraen en bucle.
  pulse,

  /// Destello de luz que barre el botón de izquierda a derecha.
  shimmer,

  /// Sombra y brillo se expanden y contraen lentamente, efecto "respiración".
  breathe,
}

// ─────────────────────────────────────────────────────────────────────────────
// GradientButtonPalette  –  paleta de colores personalizada
// ─────────────────────────────────────────────────────────────────────────────

/// Paleta de colores para [GradientButton].
///
/// Si no se proporciona, el botón usa los colores del [GradientButtonVariant].
/// Cuando se proporciona, **sobreescribe** completamente el variant.
///
/// ```dart
/// GradientButton(
///   label: 'Guardar',
///   onPressed: () {},
///   palette: GradientButtonPalette(
///     colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
///     shadowColor: Color(0xFF22C55E),
///   ),
/// )
/// ```
class GradientButtonPalette {
  const GradientButtonPalette({
    required this.colors,
    required this.shadowColor,
  }) : assert(colors.length >= 2, 'Se necesitan al menos 2 colores.');

  /// Lista de colores del degradado (mínimo 2).
  final List<Color> colors;

  /// Color de la sombra luminosa bajo el botón.
  final Color shadowColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// GradientButton
// ─────────────────────────────────────────────────────────────────────────────

/// Botón reutilizable con degradado animado, varios tipos de animación
/// y soporte para paleta de colores personalizada.
///
/// **Ejemplo básico:**
/// ```dart
/// GradientButton(
///   label: 'Crear torneo',
///   icon: Icons.emoji_events_rounded,
///   onPressed: () {},
/// )
/// ```
///
/// **Con tipo de animación y paleta personalizada:**
/// ```dart
/// GradientButton(
///   label: 'Guardar',
///   onPressed: () {},
///   animationType: AnimationType.shimmer,
///   palette: GradientButtonPalette(
///     colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
///     shadowColor: Color(0xFF22C55E),
///   ),
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
    this.palette,
    this.animationType = AnimationType.gradientShift,
    this.size = GradientButtonSize.medium,
    this.width = double.infinity,
    this.textColor = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// Variante de color predefinida. Se ignora si se proporciona [palette].
  final GradientButtonVariant variant;

  /// Paleta de colores personalizada. Sobreescribe [variant] si se proporciona.
  final GradientButtonPalette? palette;

  /// Tipo de animación. Por defecto [AnimationType.gradientShift].
  final AnimationType animationType;

  final GradientButtonSize size;
  final double width;
  final Color textColor;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButtonState extends State<GradientButton>
    with TickerProviderStateMixin {
  // Controller principal (gradientShift, subtle, pulse, breathe, shimmer)
  late final AnimationController _mainController;

  // Animaciones derivadas
  late Animation<double> _mainAnimation;

  bool _isPressed = false;

  // ── Duraciones por tipo ──────────────────────────────────────────────────

  Duration get _mainDuration => switch (widget.animationType) {
    AnimationType.gradientShift => const Duration(seconds: 4),
    AnimationType.subtle        => const Duration(milliseconds: 2200),
    AnimationType.pulse         => const Duration(milliseconds: 900),
    AnimationType.breathe       => const Duration(milliseconds: 3000),
    AnimationType.shimmer       => const Duration(milliseconds: 1800),
    AnimationType.none          => const Duration(seconds: 1),
  };

  // ── Inicialización ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: _mainDuration,
      vsync: this,
    );

    _mainAnimation = CurvedAnimation(
      parent: _mainController,
      curve: _mainCurve,
    );

    _startAnimation();
  }

  Animatable<double> get _mainCurveForAnimation => switch (widget.animationType) {
    AnimationType.pulse   => CurveTween(curve: Curves.easeInOut),
    AnimationType.subtle  => CurveTween(curve: Curves.easeInOut),
    AnimationType.breathe => CurveTween(curve: Curves.easeInOut),
    _                     => CurveTween(curve: Curves.linear),
  };

  Curve get _mainCurve => switch (widget.animationType) {
    AnimationType.pulse   => Curves.easeInOut,
    AnimationType.subtle  => Curves.easeInOut,
    AnimationType.breathe => Curves.easeInOut,
    _                     => Curves.linear,
  };

  void _startAnimation() {
    switch (widget.animationType) {
      case AnimationType.none:
      // Sin bucle, sin forward: completamente estático
        break;
      case AnimationType.pulse:
      case AnimationType.subtle:
      case AnimationType.breathe:
      // Ping-pong: crece → decrece → crece…
        _mainController.repeat(reverse: true);
      case AnimationType.gradientShift:
      case AnimationType.shimmer:
        _mainController.repeat();
    }
  }

  @override
  void didUpdateWidget(GradientButton old) {
    super.didUpdateWidget(old);
    // Si cambia el tipo de animación en caliente, reinicia el controller
    if (old.animationType != widget.animationType) {
      _mainController.stop();
      _mainController.duration = _mainDuration;
      _mainAnimation = CurvedAnimation(
        parent: _mainController,
        curve: _mainCurve,
      );
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  // ── Helpers de tamaño ────────────────────────────────────────────────────

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

  // ── Colores (palette sobreescribe variant) ───────────────────────────────

  List<Color> get _colors =>
      widget.palette?.colors ?? widget.variant.colors;

  Color get _shadowColor =>
      widget.palette?.shadowColor ?? widget.variant.shadowColor;

  // ── Build principal ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            if (!_disabled) widget.onPressed!();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: _wrapWithAnimation(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: _height),
              child: SizedBox(
                width: widget.width,
                child: _buildDecoratedButton(),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Envuelve el botón con la animación de escala/opacidad correspondiente

  Widget _wrapWithAnimation({required Widget child}) {
    return switch (widget.animationType) {
    // gradientShift: solo la escala de press, sin wrapper extra
      AnimationType.gradientShift ||
      AnimationType.none ||
      AnimationType.shimmer => AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: child,
      ),

    // subtle: escala muy suave 1.0 → 1.012 + press
      AnimationType.subtle => AnimatedScale(
        scale: _isPressed
            ? 0.97
            : 1.0 + (_mainAnimation.value * 0.012),
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: _disabled
              ? 0.55
              : 0.88 + (_mainAnimation.value * 0.12),
          child: child,
        ),
      ),

    // pulse: latido marcado 1.0 → 1.035
      AnimationType.pulse => AnimatedScale(
        scale: _isPressed
            ? 0.96
            : 1.0 + (_mainAnimation.value * 0.035),
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        child: child,
      ),

    // breathe: solo cambia la sombra (aplicado en _buildDecoratedButton)
    // y una escala mínima de respiro
      AnimationType.breathe => AnimatedScale(
        scale: _isPressed
            ? 0.97
            : 1.0 + (_mainAnimation.value * 0.008),
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: child,
      ),
    };
  }

  // ── Botón con decoración + inkwell

  Widget _buildDecoratedButton() {
    final gradientDecoration = _buildGradient();
    final shadowList = _buildShadow();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        gradient: gradientDecoration,
        boxShadow: _disabled ? [] : shadowList,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Stack(
          children: [
            // Capa base: Material + InkWell
            Material(
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
            // Capa shimmer (solo AnimationType.shimmer)
            if (widget.animationType == AnimationType.shimmer && !_disabled)
              _buildShimmerLayer(),
          ],
        ),
      ),
    );
  }

  // ── Gradiente según tipo de animación ────────────────────────────────────

  LinearGradient _buildGradient() {
    final colors = _disabled
        ? _colors.map((c) => c.withValues(alpha: 0.5)).toList()
        : _colors;

    return switch (widget.animationType) {
    // Rotación continua del eje del degradado (comportamiento original)
      AnimationType.gradientShift => () {
        final t = _mainAnimation.value;
        final begin = AlignmentTween(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).lerp(t % 1);
        final end = AlignmentTween(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ).lerp(t % 1);
        return LinearGradient(begin: begin, end: end, colors: colors);
      }(),

    // Estático: degradado fijo diagonal
      AnimationType.none => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),

    // subtle / pulse / breathe: gradiente fijo, la animación está en escala/sombra
      AnimationType.subtle ||
      AnimationType.pulse  ||
      AnimationType.breathe => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),

    // shimmer: gradiente estático; el brillo lo añade la capa encima
      AnimationType.shimmer => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
    };
  }

  // ── Sombra dinámica según tipo ───────────────────────────────────────────

  List<BoxShadow> _buildShadow() {
    final base = _isPressed ? 0.50 : 0.32;

    return switch (widget.animationType) {
      AnimationType.none => [
        BoxShadow(
          color: _shadowColor.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],

      AnimationType.gradientShift ||
      AnimationType.shimmer => [
        BoxShadow(
          color: _shadowColor.withValues(alpha: _isPressed ? 0.5 : 0.32),
          blurRadius: _isPressed ? 28 : 20,
          offset: const Offset(0, 8),
        ),
      ],

      AnimationType.subtle => [
        BoxShadow(
          color: _shadowColor.withValues(
            alpha: 0.22 + (_mainAnimation.value * 0.14),
          ),
          blurRadius: 16 + (_mainAnimation.value * 6),
          offset: const Offset(0, 6),
        ),
      ],

    // pulse: sombra que late con fuerza
      AnimationType.pulse => [
        BoxShadow(
          color: _shadowColor.withValues(
            alpha: _isPressed ? 0.60 : (0.28 + _mainAnimation.value * 0.36),
          ),
          blurRadius: _isPressed ? 32 : (14 + _mainAnimation.value * 24),
          spreadRadius: _mainAnimation.value * 3,
          offset: const Offset(0, 6),
        ),
      ],

    // breathe: sombra que "respira" lentamente
      AnimationType.breathe => [
        BoxShadow(
          color: _shadowColor.withValues(
            alpha: _isPressed ? base : (0.18 + _mainAnimation.value * 0.30),
          ),
          blurRadius: _isPressed ? 30 : (12 + _mainAnimation.value * 28),
          spreadRadius: _isPressed ? 0 : (_mainAnimation.value * 4),
          offset: const Offset(0, 6),
        ),
      ],
    };
  }

  // ── Capa shimmer ─────────────────────────────────────────────────────────

  Widget _buildShimmerLayer() {
    // El destello barre de -40% a +140% del ancho del botón
    final t = _mainAnimation.value; // 0 → 1 continuo
    // Convertimos a posición: -0.4 ... 1.4
    final shimmerPos = -0.4 + (t * 1.8);

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ShimmerPainter(
            position: shimmerPos,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
      ),
    );
  }

  // ── Contenido (icon + label / spinner) ───────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// _ShimmerPainter  –  CustomPainter para el destello de shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.position, required this.color});

  /// Posición normalizada del centro del destello (-0.4 … 1.4).
  final double position;

  /// Color base del destello (normalmente blanco semitransparente).
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Ancho del destello: ~30% del ancho del botón
    final shimmerWidth = size.width * 0.30;
    final centerX = size.width * position;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(rect);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCenter(
          center: Offset(centerX, size.height / 2),
          width: shimmerWidth,
          height: size.height,
        ),
      );

    // Inclinamos el destello ~20°
    canvas.save();
    canvas.translate(centerX, 0);
    canvas.transform(Matrix4.rotationZ(math.pi / 9).storage);
    canvas.translate(-centerX, 0);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, size.height / 2),
        width: shimmerWidth,
        height: size.height * 2, // más alto para cubrir tras la rotación
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.position != position || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum GradientButtonSize { small, medium, large }