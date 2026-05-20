import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/widgets/field_label.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.authController});

  final AuthController? authController;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();

  late final AuthController _authController;
  late final bool _ownsAuthController;

  /// `false` = formulario activo · `true` = enviado con éxito
  bool _submitted = false;
  String? _emailError;

  bool get _isLoading => _authController.isLoading;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _ownsAuthController = widget.authController == null;
    _authController = widget.authController ?? AuthController();
    _authController.addListener(_onControllerChange);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _authController.removeListener(_onControllerChange);
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    if (_ownsAuthController) _authController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  // ── Validación ──────────────────────────────────────────────────────────────

  bool _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'El correo es obligatorio.');
      return false;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Introduce un correo válido.');
      return false;
    }
    setState(() => _emailError = null);
    return true;
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_validateEmail()) return;
    if (_isLoading) return;

    await _authController.sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _submitted = true);
  }

  // ── Reintentar ──────────────────────────────────────────────────────────────

  void _handleRetry() {
    setState(() {
      _submitted = false;
      _emailController.clear();
      _emailError = null;
    });
  }

  // ── Helpers UI ──────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
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
        Positioned(
          top: -80,
          left: -60,
          child: GlowOrb(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            size: 280,
          ),
        ),
        Positioned(
          bottom: 60,
          right: -80,
          child: GlowOrb(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.25),
            size: 240,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.45,
          left: MediaQuery.of(context).size.width * 0.3,
          child: GlowOrb(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
            size: 160,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onPressed,
    bool showSpinner = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: showSpinner
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Formulario ──────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel(label: 'Correo electrónico'),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _emailController,
            hint: 'tu@correo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            enabled: !_isLoading,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
          ),
          const SizedBox(height: 28),
          _buildGradientButton(
            label: 'Enviar instrucciones',
            onPressed: _isLoading ? null : _handleSubmit,
            showSpinner: _isLoading,
          ),
        ],
      ),
    );
  }

  // ── Confirmación ────────────────────────────────────────────────────────────

  Widget _buildConfirmation() {
    return _buildCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Revisa tu correo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Si existe una cuenta con ese correo, recibirás las instrucciones para restablecer tu contraseña.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _buildGradientButton(
            label: 'Enviar de nuevo',
            onPressed: _handleRetry,
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
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
                      const SizedBox(height: 16),

                      // ── Botón volver ──────────────────────────────────────
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Encabezado ────────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF00D4FF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6C63FF,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                color: Colors.white,
                                size: 34,
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
                                'Recuperar contraseña',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Te enviaremos un enlace para restablecer\ntu contraseña',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 0.2,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Tarjeta principal ─────────────────────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _submitted
                            ? KeyedSubtree(
                                key: const ValueKey('confirmation'),
                                child: _buildConfirmation(),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('form'),
                                child: _buildForm(),
                              ),
                      ),

                      const SizedBox(height: 28),

                      // ── Enlace volver al login ─────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '¿Ya recuerdas tu contraseña? ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 14,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'Inicia sesión',
                                  style: TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
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
