import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/app_shell.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/icons/my_icons.dart';
import '../../../../core/widgets/field_label.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../../core/widgets/password_strength_bar.dart';
import '../../../../core/widgets/social_button.dart';
import '../../../../core/widgets/terms_checkbox.dart';
import 'register_dates_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Register Screen
// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nickNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _authController = AuthController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  bool get _isLoading => _authController.isLoading;

  // Validation state
  String? _nickNameError;
  String? _nameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Password strength
  double get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 6) s += 0.25;
    if (p.length >= 10) s += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.25;
    if (p.contains(RegExp(r'[0-9!@#\$%^&*]'))) s += 0.25;
    return s;
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s <= 0.25) return const Color(0xFFFF4D6A);
    if (s <= 0.5) return const Color(0xFFFFB347);
    if (s <= 0.75) return const Color(0xFF00D4FF);
    return const Color(0xFF4ADE80);
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s == 0) return '';
    if (s <= 0.25) return 'Débil';
    if (s <= 0.5) return 'Regular';
    if (s <= 0.75) return 'Buena';
    return 'Fuerte';
  }

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
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    _passwordController.addListener(() => setState(() {}));
    _authController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nickNameController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _authController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nickNameError = _nickNameController.text.trim().isEmpty
          ? 'Introduce tu nombre de usuario'
          : null;

      _nameError = _nameController.text.trim().isEmpty
          ? 'Introduce tu nombre'
          : null;

      _lastNameError = _lastNameController.text.trim().isEmpty
          ? 'Introduce tu apellido'
          : null;

      final emailReg = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
      _emailError = !emailReg.hasMatch(_emailController.text.trim())
          ? 'Correo electrónico no válido'
          : null;

      _passwordError = _passwordController.text.length < 6
          ? 'La contraseña debe tener al menos 6 caracteres'
          : null;

      _confirmError = _confirmController.text != _passwordController.text
          ? 'Las contraseñas no coinciden'
          : null;
    });

    if (_nickNameError != null ||
        _nameError != null ||
        _lastNameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmError != null) {
      valid = false;
    }
    if (!_acceptTerms) {
      valid = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes aceptar los términos y condiciones'),
          backgroundColor: const Color(0xFFFF4D6A),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return valid;
  }

  Future<void> _handleRegister() async {
    if (!_validate()) return;
    final success = await _authController.register(
      email: _emailController.text,
      password: _passwordController.text,
      nickname: _nickNameController.text,
      name: _nameController.text,
      lastName: _lastNameController.text,
    );
    if (!mounted) return;
    setState(() {});
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Cuenta creada con éxito! Bienvenido/a 🎉'),
          backgroundColor: const Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } else {
      _showError(_authController.errorMessage ?? 'Error al crear la cuenta.');
    }
  }

  Future<void> _handleGoogleRegister() async {
    final result = await _authController.loginWithGoogle();
    if (!mounted) return;
    setState(() {});
    _handleSocialResult(result);
  }

  Future<void> _handleAppleRegister() async {
    final result = await _authController.loginWithApple();
    if (!mounted) return;
    setState(() {});
    _handleSocialResult(result);
  }

  void _handleSocialResult(SocialAuthResult result) {
    switch (result) {
      case SocialAuthExisting():
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
          (_) => false,
        );
      case SocialAuthNewUser(:final uid, :final email, :final photoUrl, :final provider):
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterDatesScreen(
              uid: uid,
              email: email,
              photoUrl: photoUrl,
              provider: provider,
            ),
          ),
        );
      case SocialAuthFailure(:final message):
        _showError(message);
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

          // ── Esferas ambient ─────────────────────────────────────────
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
          Positioned(
            top: MediaQuery.of(context).size.height * 0.55,
            right: MediaQuery.of(context).size.width * 0.1,
            child: GlowOrb(
              color: const Color(0xFFFF6B9D).withOpacity(0.13),
              size: 150,
            ),
          ),

          // ── Contenido ───────────────────────────────────────────────
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
                      const SizedBox(height: 40),

                      // ── Header ────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            // Logo con icono de trofeo (contexto torneos)
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
                                'Crear cuenta',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Únete y empieza a competir',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.5),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Tarjeta glassmorphism ──────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter:
                          ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                                // ── Nickname ────────────────
                                FieldLabel(label: 'Nickname'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _nickNameController,
                                  hint: 'Tu nombre público',
                                  icon: MyFlutterApp.logo_gromy,
                                  iconSize: 50, // Increase size since custom logo looks small
                                  errorText: _nickNameError,
                                ),

                                const SizedBox(height: 20),

                                // ── Nombre ───────────────────────────
                                FieldLabel(label: 'Nombre'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _nameController,
                                  hint: 'Tu nombre',
                                  icon: Icons.person_outline_rounded,
                                  errorText: _nameError,
                                ),

                                const SizedBox(height: 20),

                                // ── Apellido ─────────────────────────
                                FieldLabel(label: 'Apellido'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _lastNameController,
                                  hint: 'Tu apellido',
                                  icon: Icons.person_outline_rounded,
                                  errorText: _lastNameError,
                                ),

                                const SizedBox(height: 20),

                                // ── Correo ───────────────────────────
                                FieldLabel(label: 'Correo electrónico'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _emailController,
                                  hint: 'tu@correo.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  errorText: _emailError,
                                ),

                                const SizedBox(height: 20),

                                // ── Contraseña ───────────────────────
                                FieldLabel(label: 'Contraseña'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _passwordController,
                                  hint: 'Mínimo 6 caracteres',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  errorText: _passwordError,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                    _obscurePassword =
                                    !_obscurePassword),
                                  ),
                                ),

                                // Barra de fortaleza de contraseña
                                if (_passwordController.text.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  PasswordStrengthBar(
                                    strength: _passwordStrength,
                                    color: _strengthColor,
                                    label: _strengthLabel,
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // ── Confirmar contraseña ─────────────
                                FieldLabel(label: 'Confirmar contraseña'),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: _confirmController,
                                  hint: 'Repite tu contraseña',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscureConfirm,
                                  errorText: _confirmError,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                            () => _obscureConfirm =
                                        !_obscureConfirm),
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // ── Términos y condiciones ───────────
                                TermsCheckbox(
                                  value: _acceptTerms,
                                  onChanged: (v) =>
                                      setState(() => _acceptTerms = v ?? false),
                                ),

                                const SizedBox(height: 28),

                                // ── Botón Registrarse ────────────────
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
                                      borderRadius:
                                      BorderRadius.circular(16),
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
                                      onPressed: _isLoading
                                          ? null
                                          : _handleRegister,
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
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                          : const Text(
                                        'Crear cuenta',
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

                      const SizedBox(height: 28),

                      // ── Divisor social ────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.12),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'o regístrate con',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.12),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Botones sociales ──────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: SocialButton(
                              label: 'Google',
                              icon: Icons.g_mobiledata_rounded,
                              onTap: _isLoading ? () {} : _handleGoogleRegister,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SocialButton(
                              label: 'Apple',
                              icon: Icons.apple_rounded,
                              onTap: _isLoading ? () {} : _handleAppleRegister,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Ir a login ────────────────────────────────
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¿Ya tienes cuenta? ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Iniciar sesión',
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

