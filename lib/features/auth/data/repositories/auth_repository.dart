import '../models/auth_result.dart';

/// Contrato abstracto de autenticación (Principio de Inversión de Dependencias).
///
/// Las pantallas y el controlador dependen de esta interfaz, nunca de
/// Firebase directamente. Esto permite sustituir la implementación
/// (p.ej. en tests) sin modificar la UI.
abstract interface class AuthRepository {
  /// Inicia sesión con correo y contraseña.
  Future<AuthResult> signInWithEmail(String email, String password);

  /// Registra un nuevo usuario con correo y contraseña.
  Future<AuthResult> registerWithEmail(String email, String password);

  /// Inicia sesión con la cuenta de Google del dispositivo.
  Future<AuthResult> signInWithGoogle();

  /// Inicia sesión con Apple ID (solo iOS/macOS con Apple Developer).
  Future<AuthResult> signInWithApple();

  /// Cierra la sesión del usuario actual.
  Future<void> signOut();
}
