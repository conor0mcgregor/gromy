import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/other_user_profile_screen.dart';
import '../../../../app/app_shell.dart';

/// Helper para manejar la navegación unificada a los perfiles de usuario.
class UserProfileNavigationHelper {
  /// Navega al perfil de un usuario dado su [userId].
  static Future<void> navigateToUserProfile(BuildContext context, String userId) async {
    if (userId.isEmpty) return;

    if (FirebaseAuth.instance.currentUser?.uid == userId) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 4)),
        (route) => false,
      );
      return;
    }
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtherUserProfileScreen(targetUid: userId),
      ),
    );
  }
}

/// Widget reutilizable que envuelve un elemento (como un avatar o card)
/// y le agrega soporte de pulsación con feedback visual consistente
/// para navegar al perfil de usuario.
class UserProfileClickable extends StatelessWidget {
  const UserProfileClickable({
    super.key,
    required this.userId,
    required this.child,
    this.borderRadius = 14,
  });

  final String? userId;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => UserProfileNavigationHelper.navigateToUserProfile(context, userId!),
        borderRadius: BorderRadius.circular(borderRadius),
        mouseCursor: SystemMouseCursors.click,
        splashColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
        highlightColor: const Color(0xFF6C63FF).withValues(alpha: 0.05),
        child: child,
      ),
    );
  }
}
