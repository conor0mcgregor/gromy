import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../user/data/models/app_user.dart';
import '../../../user/data/services/firestore_user_service.dart';
import 'package:gromy/core/widgets/gradient_button.dart';
import 'edit_profile_screen.dart';

class ProfileInfoTab extends StatefulWidget {
  const ProfileInfoTab({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfileInfoTab> createState() => _ProfileInfoTabState();
}

class _ProfileInfoTabState extends State<ProfileInfoTab> {
  bool _isLoggingOut = false;
  final _userService = FirestoreUserService();

  late Future<AppUser?> _userFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userFuture = _userService.getUser(uid);
    } else {
      _userFuture = Future.value(null);
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await widget.authController.logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo cerrar sesion. Intentalo de nuevo.'),
          backgroundColor: const Color(0xFFFF4D6A),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Error al cargar perfil', style: TextStyle(color: Colors.white)));
        }

        final user = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                  image: user.photoUrl != null
                      ? DecorationImage(
                    image: NetworkImage(user.photoUrl!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: user.photoUrl == null
                    ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),

              // Nombre completo
              Text(
                '${user.name} ${user.lastName}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Alias
              Text(
                '@${user.nickname}',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF00D4FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Bio
              if (user.biography != null && user.biography!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.biography!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Botón Editar Perfil
              GradientButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(uid: user.uid),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      _loadUser(); // Recargar datos si hubo cambios
                    });
                  }
                },
                label: 'Editar Perfil',
                icon: Icons.edit_rounded,
              ),

              const SizedBox(height: 32),

              // Botón Cerrar sesión
              GradientButton(
                onPressed: _isLoggingOut ? null : _handleLogout,
                label: _isLoggingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
                isLoading: _isLoggingOut,
                icon: Icons.logout_rounded,
              ),
            ],
          ),
        );
      },
    );
  }
}
