import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gromy/core/widgets/gradient_button.dart';
import 'package:gromy/features/tournament/presentation/screens/form_tournament_screen.dart';

import '../controllers/create_tournament_controller.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _locationController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  late final CreateTournamentController _createTournamentController;
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool get _isSubmitting => _createTournamentController.isSubmitting;

  @override
  void initState() {
    super.initState();
    _createTournamentController = CreateTournamentController();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _createTournamentController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _locationController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;

              return Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                  child: ConstrainedBox(
                    constraints:
                    BoxConstraints(maxWidth: isWide ? 880 : 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Hero ──
                        _TournamentHero(isSubmitting: _isSubmitting, subtitle: 'Rellena el formulario con los detalles del torneo para crear tu nuevo torneo.',),
                        const SizedBox(height: 20),
                        _buildSubmitButton(),
                        const SizedBox(height: 14),

                        // ── Aviso amigable ──
                        _buildReadyHint(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ──────────────── Campos ────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _isSubmitting
              ? const LinearGradient(
              colors: [Color(0xFF4A4480), Color(0xFF008FA8)])
              : const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isSubmitting
              ? []
              : [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: GradientButton(
          label: 'Crear torneo',
          icon: Icons.emoji_events_rounded,
          isLoading: _isSubmitting,
          variant: GradientButtonVariant.sunset,
          size: GradientButtonSize.large,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FormTournamentScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReadyHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF00D4FF), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Una vez creado, podrás invitar participantes y gestionar el torneo desde tu perfil.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Widgets auxiliares
// ═══════════════════════════════════════════════════════════

/// Hero / cabecera de la pantalla
class _TournamentHero extends StatelessWidget {
  const _TournamentHero({required this.subtitle, required this.isSubmitting});

  final String subtitle;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.16),
                const Color(0xFF00D4FF).withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF6C63FF,
                          ).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                          ).createShader(bounds),
                          child:
                          const Text(
                            'Nuevo torneo',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroChip(icon: Icons.storage_rounded, label: 'Gestiona los partisipantes'),
                  _HeroChip(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Añade Administradores',
                  ),
                  _HeroChip(
                    icon: isSubmitting
                        ? Icons.sync_rounded
                        : Icons.verified_rounded,
                    label: 'Comparte tu torneo',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00D4FF)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
