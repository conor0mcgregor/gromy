/// Resultado sellado de una operación de autenticación.
sealed class AuthResult {}

/// La operación de auth se completó correctamente.
///
/// [isNewUser] es `true` cuando el usuario acaba de crearse en Firebase Auth
/// por primera vez (login social) y **no** tiene aún su perfil en Firestore.
final class AuthSuccess extends AuthResult {
  AuthSuccess({this.isNewUser = false});

  /// Indica si el usuario es nuevo (necesita completar su perfil).
  final bool isNewUser;
}

/// La operación de auth falló con un [message] legible por el usuario.
final class AuthFailure extends AuthResult {
  AuthFailure(this.message);

  final String message;
}
