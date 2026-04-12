import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
//  TOGGLE SWITCH — Widget reutilizable con animación
//
//  Ejemplo de uso:
//
//    ToggleSwitch(
//      value: _isOn,
//      onChanged: (v) => setState(() => _isOn = v),
//      label: 'Notificaciones',
//      description: 'Recibir alertas del torneo',
//    )
//
//  Variantes de color disponibles: violet (defecto), green, teal, coral
// ════════════════════════════════════════════════════════════════

enum ToggleSwitchColor { violet, green, teal, coral }

class ToggleSwitch extends StatefulWidget {
  const ToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.color = ToggleSwitchColor.violet,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? description;
  final ToggleSwitchColor color;
  final bool enabled;

  @override
  State<ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<ToggleSwitch>
    with TickerProviderStateMixin {
  // ── Deslizamiento del thumb ──
  late final AnimationController _slideCtrl;
  late final Animation<double> _slideAnim;

  // ── Ensanchamiento del thumb al presionar ──
  late final AnimationController _squishCtrl;
  late final Animation<double> _squishAnim;

  // ── Ripple de toque ──
  late final AnimationController _rippleCtrl;
  late final Animation<double> _rippleRadius;
  late final Animation<double> _rippleOpacity;

  // ── Color del track ──
  late final AnimationController _colorCtrl;

  static const double _trackW = 52;
  static const double _trackH = 30;
  static const double _thumbSize = 22;
  static const double _thumbPad = 4;
  static const double _travel = _trackW - _thumbSize - _thumbPad * 2;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
    _slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeInOut,
    );

    _squishCtrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _squishAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _squishCtrl, curve: Curves.easeOut),
    );

    _rippleCtrl = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _rippleRadius = Tween<double>(begin: 0, end: 36).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.18, end: 0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeIn),
    );

    _colorCtrl = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(ToggleSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      if (widget.value) {
        _slideCtrl.forward();
        _colorCtrl.forward();
      } else {
        _slideCtrl.reverse();
        _colorCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _squishCtrl.dispose();
    _rippleCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  //  Colores según variante
  // ──────────────────────────────────────────────────────────────

  Color get _activeColor => switch (widget.color) {
    ToggleSwitchColor.violet => const Color(0xFF534AB7),
    ToggleSwitchColor.green  => const Color(0xFF3B6D11),
    ToggleSwitchColor.teal   => const Color(0xFF0F6E56),
    ToggleSwitchColor.coral  => const Color(0xFF993C1D),
  };

  Color get _rippleColor => _activeColor.withValues(alpha: 0.15);

  Color get _inactiveTrack => const Color(0xFFB4B2A9);

  // ──────────────────────────────────────────────────────────────
  //  Interacción
  // ──────────────────────────────────────────────────────────────

  Future<void> _handleTap() async {
    if (!widget.enabled) return;

    // Squish de entrada
    await _squishCtrl.forward();
    _squishCtrl.reverse();

    // Ripple
    _rippleCtrl.forward(from: 0);

    widget.onChanged(!widget.value);
  }

  // ──────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasText =
        widget.label != null || widget.description != null;

    final toggle = Semantics(
      toggled: widget.value,
      label: widget.label,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _slideAnim,
            _squishAnim,
            _rippleRadius,
            _rippleOpacity,
            _colorCtrl,
          ]),
          builder: (context, _) {
            final thumbW = _thumbSize + _squishAnim.value * 6;
            final thumbX = _slideAnim.value * _travel;
            final trackColor = Color.lerp(
              _inactiveTrack,
              _activeColor,
              _colorCtrl.value,
            )!;
            final opacity = widget.enabled ? 1.0 : 0.4;

            return Opacity(
              opacity: opacity,
              child: SizedBox(
                width: _trackW,
                height: _trackH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Ripple de toque (por fuera del track) ──
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: _rippleRadius.value * 2,
                          height: _rippleRadius.value * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _rippleColor.withValues(
                              alpha: _rippleOpacity.value,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Track ──
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: Duration.zero,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: trackColor,
                        ),
                      ),
                    ),

                    // ── Thumb ──
                    Positioned(
                      top: _thumbPad,
                      left: _thumbPad + thumbX,
                      child: Container(
                        width: thumbW,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: widget.value ? 1.0 : 0.0,
                            child: Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: _activeColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    // Sin etiqueta: devuelve solo el track
    if (!hasText) return toggle;

    // Con etiqueta: fila completa
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: TextStyle(
                    color: widget.enabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (widget.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.description!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        toggle,
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  TOGGLE SWITCH LIST — Contenedor de varios toggles
//
//  Ejemplo de uso:
//
//    ToggleSwitchList(
//      items: [
//        ToggleSwitchItem(
//          label: 'Notificaciones',
//          description: 'Recibir alertas del torneo',
//          value: _notif,
//          onChanged: (v) => setState(() => _notif = v),
//        ),
//        ToggleSwitchItem(
//          label: 'Inscripción abierta',
//          value: _open,
//          color: ToggleSwitchColor.green,
//          onChanged: (v) => setState(() => _open = v),
//        ),
//      ],
//    )
// ════════════════════════════════════════════════════════════════

class ToggleSwitchItem {
  const ToggleSwitchItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.color = ToggleSwitchColor.violet,
    this.enabled = true,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ToggleSwitchColor color;
  final bool enabled;
}

class ToggleSwitchList extends StatelessWidget {
  const ToggleSwitchList({
    super.key,
    required this.items,
  });

  final List<ToggleSwitchItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          ToggleSwitch(
            value: items[i].value,
            onChanged: items[i].onChanged,
            label: items[i].label,
            description: items[i].description,
            color: items[i].color,
            enabled: items[i].enabled,
          ),
          if (i < items.length - 1) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.07),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}