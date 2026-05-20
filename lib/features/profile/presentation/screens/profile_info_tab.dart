import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../account/presentation/widgets/delete_account_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../user/data/models/app_user.dart';
import '../../../user/data/services/firestore_user_service.dart';
import 'package:gromy/core/widgets/gradient_button.dart';
import 'edit_profile_screen.dart';
import 'historical_tournaments_screen.dart';

class ProfileInfoTab extends StatefulWidget {
  const ProfileInfoTab({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfileInfoTab> createState() => _ProfileInfoTabState();
}

class _ProfileInfoTabState extends State<ProfileInfoTab> {
  bool _isLoggingOut = false;
  FirestoreUserService? _userService;

  late Future<AppUser?> _userFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final uid = _currentUid();
    if (uid != null) {
      _userService ??= FirestoreUserService();
      _userFuture = _userService!.getUser(uid);
    } else {
      _userFuture = SynchronousFuture(null);
    }
  }

  String? _currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00D4FF), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Future<void> _openDeleteAccountFlow() async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );

    if (!mounted || deleted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu cuenta ha sido eliminada correctamente.'),
        backgroundColor: Color(0xFF22C55E),
      ),
    );
  }

  Widget _buildLogoutButton() {
    final label = _isLoggingOut ? 'Cerrando sesion...' : 'Cerrar sesion';
    if (_currentUid() == null) {
      return FilledButton.icon(
        onPressed: _isLoggingOut ? null : _handleLogout,
        icon: const Icon(Icons.logout_rounded),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD60039),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
        ),
      );
    }

    return GradientButton(
      onPressed: _isLoggingOut ? null : _handleLogout,
      label: label,
      isLoading: _isLoggingOut,
      icon: Icons.logout_rounded,
      variant: GradientButtonVariant.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Error al cargar perfil',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                _buildLogoutButton(),
              ],
            ),
          );
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
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  image: user.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.photoUrl == null
                    ? const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: Colors.white,
                      )
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

              // Información estructurada
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.email_outlined,
                      'Correo electrónico',
                      user.email,
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'Miembro desde',
                      '${user.createdAt.day.toString().padLeft(2, '0')}/${user.createdAt.month.toString().padLeft(2, '0')}/${user.createdAt.year}',
                    ),
                    if (user.biography != null &&
                        user.biography!.isNotEmpty) ...[
                      const Divider(color: Colors.white12, height: 1),
                      _buildInfoRow(
                        Icons.info_outline_rounded,
                        'Biografía',
                        user.biography!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

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
                variant: GradientButtonVariant.simple,
                textColor: Colors.black,
              ),

              const SizedBox(height: 16),

              // Botón Historial de Torneos
              GradientButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoricalTournamentsScreen(uid: user.uid),
                    ),
                  );
                },
                label: 'Historial de Torneos',
                icon: Icons.history_rounded,
                variant: GradientButtonVariant.ocean,
              ),

              const SizedBox(height: 32),

              // Botón Cerrar sesión
              _buildLogoutButton(),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF4D6A).withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.dangerous_rounded, color: Color(0xFFFF8A8A)),
                        SizedBox(width: 10),
                        Text(
                          'Zona peligrosa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Gestiona la baja de tu cuenta y la anonimizacion de tus datos personales.',
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      onPressed: _openDeleteAccountFlow,
                      label: 'Eliminar cuenta',
                      icon: Icons.delete_forever_rounded,
                      variant: GradientButtonVariant.danger,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
