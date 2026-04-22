import 'package:flutter/material.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:gromy/core/widgets/gradient_button.dart';

class ProfileInfoTab extends StatefulWidget {
  const ProfileInfoTab({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfileInfoTab> createState() => _ProfileInfoTabState();
}

class _ProfileInfoTabState extends State<ProfileInfoTab> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await widget.authController.logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo cerrar sesion. Intentalo de nuevo.'),
          backgroundColor: const Color(0xFFFF4D6A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
            ).createShader(bounds),
            child: const Icon(
              Icons.person_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
            ).createShader(bounds),
            child: const Text(
              'Perfil',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pantalla en construccion',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GradientButton(
              onPressed: _isLoggingOut ? null : _handleLogout,
              label: _isLoggingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
              isLoading: _isLoggingOut,
              icon: Icons.logout_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
