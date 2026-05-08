import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/widgets/glow_orb.dart';

class FinishDemoScreen extends StatefulWidget {
  const FinishDemoScreen({super.key});

  @override
  State<FinishDemoScreen> createState() => _FinishDemoScreenState();
}

class _FinishDemoScreenState extends State<FinishDemoScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  late final AnimationController _shimmerController;

  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  late final Animation<double> _pulse;
  late final Animation<double> _float;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    // Fade + slide on entry
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // Pulse for the icon ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Float for the icon container
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Shimmer for the divider line
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo degradado oscuro ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0608),
                  Color(0xFF1A0A0E),
                  Color(0xFF260D14),
                  Color(0xFF1A0A0E),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // ── Orbes ambientales ───────────────────────────────────────
          Positioned(
            top: -100,
            left: -80,
            child: GlowOrb(
              color: const Color(0xFFFF6B35).withOpacity(0.30),
              size: 320,
            ),
          ),
          Positioned(
            bottom: 80,
            right: -100,
            child: GlowOrb(
              color: const Color(0xFFFF0048).withOpacity(0.22),
              size: 280,
            ),
          ),
          Positioned(
            top: size.height * 0.5,
            left: size.width * 0.25,
            child: GlowOrb(
              color: const Color(0xFFFF4D7D).withOpacity(0.12),
              size: 180,
            ),
          ),


          // ── Contenido principal ─────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeIn.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Icono flotante con pulso ──────────────────────
                      AnimatedBuilder(
                        animation: Listenable.merge([_pulseController, _floatController]),
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _float.value),
                            child: Transform.scale(
                              scale: _pulse.value,
                              child: child,
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Anillo exterior difuminado
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFF4D7D).withOpacity(0.15),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Anillo medio
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFF4D7D).withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                            ),
                            // Contenedor principal del icono
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3D1520),
                                    Color(0xFF1F0A10),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFFF4D7D).withOpacity(0.45),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF1744).withOpacity(0.35),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFF6B35).withOpacity(0.15),
                                    blurRadius: 50,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.hourglass_top_rounded,
                                size: 34,
                                color: Color(0xFFFF6B9D),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Etiqueta "DEMO" ───────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFF4D7D).withOpacity(0.4),
                            width: 1,
                          ),
                          color: const Color(0xFFFF1744).withOpacity(0.08),
                        ),
                        child: Text(
                          'DEMO FINALIZADA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.5,
                            color: const Color(0xFFFF6B9D).withOpacity(0.9),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Título principal ──────────────────────────────
                      const Text(
                        'Tiempo\nagotado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -1.5,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Texto descriptivo ─────────────────────────────
                      Text(
                        'El periodo de la demo ha finalizado, la APP todavia no esta lista para el uso publico aun, seguiremos con su desarrolo para su lanzamiento con todas las funcionalidades',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w400,
                          height: 1.7,
                          letterSpacing: 0.2,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Tarjeta "Próximamente" ─────────────────────────
                      _ComingSoonCard(),

                      const SizedBox(height: 48),

                      // ── Footer ────────────────────────────────────────
                      Text(
                        'Gracias por ser parte de esta etapa\n¡Nos vemos en el lanzamiento! 🚀',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.white.withOpacity(0.30),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            )
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de "Próximamente" ───────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1744).withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _FeatureRow(
            icon: Icons.rocket_launch_rounded,
            label: 'Lanzamiento oficial',
            sublabel: 'pronto',
            iconColor: const Color(0xFFFF6B35),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: Colors.white.withOpacity(0.07),
              thickness: 1,
            ),
          ),
          _FeatureRow(
            icon: Icons.auto_awesome_rounded,
            label: 'Nuevas funcionalidades',
            sublabel: 'En desarrollo',
            iconColor: const Color(0xFFFF4D7D),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: Colors.white.withOpacity(0.07),
              thickness: 1,
            ),
          ),
          _FeatureRow(
            icon: Icons.verified_rounded,
            label: 'Experiencia completa',
            sublabel: 'Prometido',
            iconColor: const Color(0xFFFF8D63),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color iconColor;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: iconColor.withOpacity(0.12),
            border: Border.all(
              color: iconColor.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.40),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withOpacity(0.7),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pintor de textura de ruido ──────────────────────────────────────────────

class _NoisePainter extends CustomPainter {
  final _random = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final count = (size.width * size.height * 0.03).toInt();
    for (var i = 0; i < count; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) => false;
}