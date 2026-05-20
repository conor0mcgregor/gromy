import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Reautentica al usuario antes de operaciones sensibles (eliminar cuenta).
class AccountReauthService {
  AccountReauthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<String?> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      return 'No se pudo verificar tu identidad.';
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageForCode(e.code);
    } catch (_) {
      return 'No se pudo verificar tu contrasena.';
    }
  }

  Future<String?> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) return 'No hay una sesion activa.';

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await user.reauthenticateWithPopup(provider);
        return null;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        return 'No se pudo obtener el token de Google.';
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await user.reauthenticateWithCredential(credential);
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return 'Verificacion con Google cancelada.';
      }
      return 'No se pudo verificar con Google.';
    } on FirebaseAuthException catch (e) {
      return _messageForCode(e.code);
    } catch (_) {
      return 'No se pudo verificar con Google.';
    }
  }

  Future<String?> reauthenticateWithApple() async {
    final user = _auth.currentUser;
    if (user == null) return 'No hay una sesion activa.';

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
      await user.reauthenticateWithCredential(oauthCredential);
      return null;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return 'Verificacion con Apple cancelada.';
      }
      return 'No se pudo verificar con Apple.';
    } on FirebaseAuthException catch (e) {
      return _messageForCode(e.code);
    } catch (_) {
      return 'No se pudo verificar con Apple.';
    }
  }

  String primaryProviderId() {
    final user = _auth.currentUser;
    if (user == null) return 'password';
    if (user.providerData.any((p) => p.providerId == 'google.com')) {
      return 'google.com';
    }
    if (user.providerData.any((p) => p.providerId == 'apple.com')) {
      return 'apple.com';
    }
    return 'password';
  }

  String _messageForCode(String code) {
    return switch (code) {
      'wrong-password' => 'Contrasena incorrecta.',
      'invalid-credential' => 'Credenciales invalidas.',
      'too-many-requests' => 'Demasiados intentos. Espera un momento.',
      'network-request-failed' => 'Sin conexion a internet.',
      'user-mismatch' => 'La cuenta verificada no coincide con la sesion actual.',
      _ => 'No se pudo verificar tu identidad ($code).',
    };
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
