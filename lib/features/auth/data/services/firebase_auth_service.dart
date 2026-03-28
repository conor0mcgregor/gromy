import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../repositories/auth_repository.dart';
import '../models/auth_result.dart';

/// Implementación de [AuthRepository] respaldada por Firebase Auth.
///
/// Responsabilidades (Single Responsibility):
///   - Traducir llamadas de dominio a llamadas de Firebase.
///   - Capturar [FirebaseAuthException] y devolverlas como [AuthFailure]
///     con mensajes en español listos para mostrar al usuario.
class FirebaseAuthService implements AuthRepository {
  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ── Email / Contraseña ──────────────────────────────────────────────────────

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthSuccess();
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_emailErrorMessage(e.code));
    } catch (_) {
      return AuthFailure('Error inesperado. Inténtalo de nuevo.');
    }
  }

  @override
  Future<AuthResult> registerWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthSuccess();
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_emailErrorMessage(e.code));
    } catch (_) {
      return AuthFailure('Error inesperado. Inténtalo de nuevo.');
    }
  }

  // ── Google ──────────────────────────────────────────────────────────────────

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      // google_sign_in v7+: singleton + authenticate()
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        return AuthFailure('No se pudo obtener el token de Google.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      return AuthSuccess(isNewUser: isNewUser);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return AuthFailure('Inicio de sesión con Google cancelado.');
      }
      return AuthFailure('Error con Google Sign‑In: ${e.description}');
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_emailErrorMessage(e.code));
    } catch (_) {
      return AuthFailure('No se pudo iniciar sesión con Google.');
    }
  }

  // ── Apple ───────────────────────────────────────────────────────────────────

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      return AuthSuccess(isNewUser: isNewUser);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthFailure('Inicio de sesión con Apple cancelado.');
      }
      return AuthFailure('Error con Apple Sign‑In: ${e.message}');
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_emailErrorMessage(e.code));
    } catch (_) {
      return AuthFailure('No se pudo iniciar sesión con Apple.');
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]);
  }

  // ── Helpers privados ────────────────────────────────────────────────────────

  /// Convierte los códigos de error de Firebase en mensajes en español.
  String _emailErrorMessage(String code) {
    return switch (code) {
      'user-not-found' => 'No existe ninguna cuenta con ese correo.',
      'wrong-password' => 'Contraseña incorrecta. Inténtalo de nuevo.',
      'invalid-credential' => 'Correo o contraseña incorrectos.',
      'email-already-in-use' => 'Ese correo ya está registrado.',
      'invalid-email' => 'El correo electrónico no es válido.',
      'weak-password' => 'La contraseña es demasiado débil (mínimo 6 caracteres).',
      'user-disabled' => 'Esta cuenta ha sido deshabilitada.',
      'too-many-requests' => 'Demasiados intentos fallidos. Espera un momento.',
      'network-request-failed' => 'Sin conexión a internet.',
      'operation-not-allowed' => 'Este método de inicio de sesión no está habilitado.',
      _ => 'Error de autenticación ($code).',
    };
  }

  /// Genera un nonce aleatorio de 32 bytes codificado en base64url.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Devuelve el hash SHA‑256 de [input] en hexadecimal.
  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
