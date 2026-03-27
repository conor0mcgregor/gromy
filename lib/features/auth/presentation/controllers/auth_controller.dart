import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/models/auth_result.dart';
import '../../data/services/firebase_auth_service.dart';

/// Controlador de autenticación basado en [ChangeNotifier].
///
/// Principios SOLID aplicados:
///   - **SRP**: gestiona únicamente el estado y la lógica de auth.
///   - **DIP**: recibe [AuthRepository] por constructor; por defecto usa
///     [FirebaseAuthService] pero se puede inyectar cualquier otra
///     implementación (p.ej. un mock en tests).
///
/// Las pantallas deben escuchar [isLoading] y [errorMessage] para
/// actualizar su UI, y llamar a los métodos de este controlador en
/// respuesta a la interacción del usuario.
class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
      : _repo = repository ?? FirebaseAuthService();

  final AuthRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Email / Contraseña ──────────────────────────────────────────────────────

  /// Inicia sesión con [email] y [password].
  /// Devuelve `true` si tuvo éxito.
  Future<bool> login(String email, String password) async {
    return _run(() => _repo.signInWithEmail(email, password));
  }

  /// Registra un nuevo usuario con [email] y [password].
  /// Devuelve `true` si tuvo éxito.
  Future<bool> register(String email, String password) async {
    return _run(() => _repo.registerWithEmail(email, password));
  }

  // ── Redes sociales ──────────────────────────────────────────────────────────

  /// Inicia sesión con Google.
  /// Devuelve `true` si tuvo éxito.
  Future<bool> loginWithGoogle() async {
    return _run(() => _repo.signInWithGoogle());
  }

  /// Inicia sesión con Apple.
  /// Devuelve `true` si tuvo éxito.
  Future<bool> loginWithApple() async {
    return _run(() => _repo.signInWithApple());
  }

  /// Cierra la sesión activa.
  Future<void> logout() => _repo.signOut();

  // ── Helper interno ──────────────────────────────────────────────────────────

  /// Ejecuta [operation], actualiza [isLoading] y maneja [AuthResult].
  /// Devuelve `true` en [AuthSuccess], `false` en [AuthFailure].
  Future<bool> _run(Future<AuthResult> Function() operation) async {
    _setLoading(true);
    _clearError();

    final result = await operation();

    _setLoading(false);

    switch (result) {
      case AuthSuccess():
        return true;
      case AuthFailure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
