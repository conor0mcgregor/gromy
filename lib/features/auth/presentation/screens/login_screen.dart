import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gromy/features/auth/presentation/screens/register_screen.dart';

import '../../../../app/app_shell.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/widgets/field_label.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../../core/widgets/social_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  bool _obscurePassword = true;

  bool get _isLoading => _authController.isLoading;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final success = await _authController.login(
      _emailController.text,
      _passwordController.text,
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
      _showError(_authController.errorMessage ?? 'Error desconocido.');
    }
  }

  Future<void> _handleGoogleLogin() async {
    final success = await _authController.loginWithGoogle();
    if (!mounted) return;
    setState(() {});
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } else {
      _showError(_authController.errorMessage ?? 'Error con Google.');
    }
  }

  Future<void> _handleAppleLogin() async {
    final success = await _authController.loginWithApple();
    if (!mounted) return;
    setState(() {});
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } else {
      _showError(_authController.errorMessage ?? 'Error con Apple.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4D6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Color(0xFF0A0A1A),
                  Color(0xFF0D0D2B),
                  Color(0xFF12122E),
                ],
              ),
            ),
          ),

          // ── Esferas de color difuminadas (ambiente) ─────────────────
          Positioned(
            top: -80,
            left: -60,
            child: GlowOrb(
              color: const Color(0xFF6C63FF).withOpacity(0.35),
              size: 280,
            ),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: GlowOrb(
              color: const Color(0xFF00D4FF).withOpacity(0.25),
              size: 240,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: MediaQuery.of(context).size.width * 0.3,
            child: GlowOrb(
              color: const Color(0xFFFF6B9D).withOpacity(0.15),
              size: 160,
            ),
          ),

          // ── Contenido principal ─────────────────────────────────────
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
                      const SizedBox(height: 60),

                      // Logo / Título
                      Center(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF).withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Transform.scale(
                                  scale: 1.7, // zoom
                                  child: Image.asset(
                                    'assets/images/LOGO.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
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
                                'Bienvenido',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Inicia sesión para continuar',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.5),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── Tarjeta glassmorphism ──────────────────────
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
                                // Campo email
                                const FieldLabel(label: 'Correo electrónico'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _emailController,
                                  hint: 'tu@correo.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                const SizedBox(height: 22),

                                // Campo contraseña
                                const FieldLabel(label: 'Contraseña'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _passwordController,
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                            () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // ¿Olvidaste tu contraseña?
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        color: const Color(0xFF6C63FF)
                                            .withOpacity(0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // Botón Iniciar sesión
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
                                      onPressed:
                                      _isLoading ? null : _handleLogin,
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
                                        'Iniciar sesión',
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

                      const SizedBox(height: 32),

                      // Divisor
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                                color: Colors.white.withOpacity(0.12),
                                thickness: 1),
                          ),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'o continúa con',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                                color: Colors.white.withOpacity(0.12),
                                thickness: 1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Botones sociales
                      Row(
                        children: [
                          Expanded(
                            child: SocialButton(
                              label: 'Google',
                              icon: Icons.g_mobiledata_rounded,
                              onTap: _isLoading ? () {} : _handleGoogleLogin,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SocialButton(
                              label: 'Apple',
                              icon: Icons.apple_rounded,
                              onTap: _isLoading ? () {} : _handleAppleLogin,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // Registro
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¿No tienes cuenta? ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              ),
                              child: const Text(
                                'Regístrate',
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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
