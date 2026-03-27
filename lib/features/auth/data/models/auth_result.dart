/// Resultado sellado de una operación de autenticación.
///
/// Uso:
/// ```dart
/// final result = await authRepository.signInWithEmail(email, password);
/// switch (result) {
///   case AuthSuccess():  // navegar
///   case AuthFailure(:final message): // mostrar error
/// }
/// ```
sealed class AuthResult {}

/// La operación de auth se completó correctamente.
final class AuthSuccess extends AuthResult {}

/// La operación de auth falló con un [message] legible por el usuario.
final class AuthFailure extends AuthResult {
  AuthFailure(this.message);

  final String message;
}
