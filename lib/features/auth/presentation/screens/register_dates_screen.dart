import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/app_shell.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/widgets/field_label.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/glow_orb.dart';

/// Pantalla para completar el perfil de un usuario que se registró
/// mediante Google o Apple y aún no tiene datos en Firestore.
///
/// Recibe [uid], [email], [photoUrl] y [provider] del proceso de auth social.
class RegisterDatesScreen extends StatefulWidget {
  const RegisterDatesScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.provider,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String provider;
  final String? photoUrl;

  @override
  State<RegisterDatesScreen> createState() => _RegisterDatesScreenState();
}

class _RegisterDatesScreenState extends State<RegisterDatesScreen>
    with TickerProviderStateMixin {
  final _authController = AuthController();
  final _nicknameController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String? _nicknameError;
  String? _nameError;
  String? _lastNameError;

  bool get _isLoading => _authController.isLoading;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    _authController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nicknameController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _authController.dispose();
    super.dispose();
  }

  // ── Validación local ────────────────────────────────────────────────────────

  bool _validate() {
    bool valid = true;
    setState(() {
      _nicknameError = _nicknameController.text.trim().isEmpty
          ? 'Introduce un nombre de usuario'
          : null;
      _nameError = _nameController.text.trim().isEmpty
          ? 'Introduce tu nombre'
          : null;
      _lastNameError = _lastNameController.text.trim().isEmpty
          ? 'Introduce tu apellido'
          : null;
    });
    if (_nicknameError != null || _nameError != null || _lastNameError != null) {
      valid = false;
    }
    return valid;
  }

  // ── Guardar perfil ──────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    if (!_validate()) return;

    final success = await _authController.completeSocialProfile(
      uid: widget.uid,
      email: widget.email,
      nickname: _nicknameController.text,
      name: _nameController.text,
      lastName: _lastNameController.text,
      provider: widget.provider,
      photoUrl: widget.photoUrl,
    );

    if (!mounted) return;
    setState(() {});

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } else {
      // Nickname ya en uso → mostrar en el campo
      setState(() {
        _nicknameError = _authController.errorMessage;
      });
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A1A),
                  Color(0xFF0D0D2B),
                  Color(0xFF12122E),
                ],
              ),
            ),
          ),

          // Esferas ambient
          Positioned(
            top: -60,
            left: -80,
            child: GlowOrb(
              color: const Color(0xFF6C63FF).withOpacity(0.30),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 80,
            right: -70,
            child: GlowOrb(
              color: const Color(0xFF00D4FF).withOpacity(0.20),
              size: 220,
            ),
          ),

          // Contenido
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

                      // Header
                      Center(
                        child: Column(
                          children: [
                            // Avatar del proveedor social
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF00D4FF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF6C63FF).withOpacity(0.4),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFB0A8FF),
                                    ],
                                  ).createShader(bounds),
                              child: const Text(
                                'Completa tu perfil',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Solo nos faltan unos datos más',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Tarjeta glassmorphism
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email (solo lectura)
                                const FieldLabel(label: 'Correo electrónico'),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.email_outlined,
                                          color: Colors.white.withOpacity(0.3),
                                          size: 18),
                                      const SizedBox(width: 12),
                                      Text(
                                        widget.email,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // Nickname
                                const FieldLabel(label: 'Nickname'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _nicknameController,
                                  hint: 'Tu nombre público único',
                                  icon: Icons.alternate_email_rounded,
                                  errorText: _nicknameError,
                                ),

                                const SizedBox(height: 20),

                                // Nombre
                                const FieldLabel(label: 'Nombre'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _nameController,
                                  hint: 'Tu nombre',
                                  icon: Icons.person_outline_rounded,
                                  errorText: _nameError,
                                ),

                                const SizedBox(height: 20),

                                // Apellido
                                const FieldLabel(label: 'Apellido'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _lastNameController,
                                  hint: 'Tu apellido',
                                  icon: Icons.person_outline_rounded,
                                  errorText: _lastNameError,
                                ),

                                const SizedBox(height: 32),

                                // Botón guardar
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6C63FF),
                                          Color(0xFF00D4FF),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6C63FF)
                                              .withOpacity(0.45),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleSave,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Guardar y continuar',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.4,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
