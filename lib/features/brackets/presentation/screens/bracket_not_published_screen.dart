import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BracketNotPublishedScreen  ·  Presentation
//
//  Pantalla que se muestra cuando el bracket aún no ha sido publicado.
//  Los usuarios ven un mensaje indicativo. Los admins ven opciones de
//  generación.
// ─────────────────────────────────────────────────────────────────────────────

class BracketNotPublishedScreen extends StatelessWidget {
  const BracketNotPublishedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enfrentamientos',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono decorativo con glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  size: 42,
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),

              // Título
              const Text(
                'El bracket aún no ha sido publicado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),

              // Subtítulo
              Text(
                'El cuadro de enfrentamientos aún no ha sido publicado por los organizadores.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Recibirás una notificación cuando esté disponible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
