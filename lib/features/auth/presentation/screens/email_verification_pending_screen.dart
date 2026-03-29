import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../database/session/models/app_access_state.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../controllers/auth_controller.dart';
import 'auth_gate_screen.dart';

class EmailVerificationPendingScreen extends StatefulWidget {
  const EmailVerificationPendingScreen({
    super.key,
    required this.accessState,
    this.authController,
    this.successBuilder,
  });

  final AppAccessPendingEmailRegistration accessState;
  final AuthController? authController;
  final WidgetBuilder? successBuilder;

  @override
  State<EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends State<EmailVerificationPendingScreen> {
  late final AuthController _authController;
  late final bool _ownsAuthController;

  bool get _isLoading => _authController.isLoading;

  @override
  void initState() {
    super.initState();
    _ownsAuthController = widget.authController == null;
    _authController = widget.authController ?? AuthController();
    _authController.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_handleControllerChanged);
    if (_ownsAuthController) {
      _authController.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleCompleteRegistration() async {
    final success = await _authController.completePendingEmailRegistration();
    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: widget.successBuilder ?? (_) => const AuthGateScreen(),
        ),
            (_) => false,
      );
    } else {
      _showMessage(
        _authController.errorMessage ?? 'No pudimos completar el registro. Inténtalo de nuevo.',
        isError: true,
      );
    }
  }

  Future<void> _handleResendVerification() async {
    final success = await _authController.resendVerificationEmail();
    if (!mounted) return;

    if (success) {
      _showMessage('✅ Hemos reenviado el correo de verificación a tu bandeja de entrada.');
    } else {
      _showMessage(
        _authController.errorMessage ?? 'No se pudo reenviar el correo. Inténtalo más tarde.',
        isError: true,
      );
    }
  }

  Future<void> _handleLogout() async {
    await _authController.logout();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFFF4D6A)
            : const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessState = widget.accessState;
    final bool isVerified = accessState.emailVerified;

    final String title = isVerified
        ? '¡Correo verificado!'
        : 'Verifica tu correo electrónico';

    final String subtitle = isVerified
        ? 'Tu correo ya está confirmado. Solo falta completar tu registro.'
        : 'Te hemos enviado un enlace de verificación a:\n${accessState.email}\n\nRevisa tu bandeja de entrada (y la carpeta de spam).';

    final String primaryButtonText = isVerified
        ? 'Continuar y completar mi perfil'
        : 'Ya verifiqué mi correo';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con gradiente
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

          // Orbes decorativos
          Positioned(
            top: -60,
            right: -80,
            child: GlowOrb(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              size: 280,
            ),
          ),
          Positioned(
            bottom: 80,
            left: -70,
            child: GlowOrb(
              color: const Color(0xFF00D4FF).withOpacity(0.22),
              size: 220,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: 520,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icono grande
                          Icon(
                            isVerified
                                ? Icons.check_circle_rounded
                                : Icons.mark_email_read_rounded,
                            size: 72,
                            color: isVerified
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFB0A8FF),
                          ),

                          const SizedBox(height: 24),

                          // Título
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Subtítulo
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15.5,
                              height: 1.55,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Botón principal
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleCompleteRegistration,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                                    : Text(
                                  primaryButtonText,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Botón de reenviar
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleResendVerification,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isVerified
                                    ? 'Reenviar correo de verificación'
                                    : 'Reenviar correo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Cerrar sesión
                          TextButton(
                            onPressed: _isLoading ? null : _handleLogout,
                            child: Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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