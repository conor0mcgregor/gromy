import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_user.dart';
import '../repositories/user_repository.dart';

/// Implementación de [UserRepository] usando Cloud Firestore.
///
/// Colección: /users/{uid}
/// Responsabilidad única: persistir y recuperar datos de usuario.
class FirestoreUserService implements UserRepository {
  FirestoreUserService({FirebaseFirestore? firestore})
      : _db = firestore ??
            FirebaseFirestore.instanceFor(
                app: Firebase.app(), databaseId: 'gromy-db');

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Escritura ───────────────────────────────────────────────────────────────

  @override
  Future<void> createUser(AppUser user) async {
    try {
      print("[FIRESTORE] 1. Intentando guardar datos para el UID: ${user.uid}");

      final datosMap = user.copyWith(nickname: _normalizeNickname(user.nickname)).toMap();
      print("[FIRESTORE] 2. Datos convertidos correctamente: $datosMap");

      // Intentamos guardarlos en la base de datos
      await _users.doc(user.uid).set(datosMap).timeout(const Duration(seconds: 10));

      print("[FIRESTORE] 3. ¡ÉXITO! Los datos se guardaron en Firestore.");

    } catch (e) {
      print("[FIRESTORE] ERROR CRÍTICO AL GUARDAR: $e");
      rethrow; // Lanzamos el error hacia arriba para que la pantalla de carga se apague
    }
  }

  // ── Lectura ─────────────────────────────────────────────────────────────────

  @override
  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get().timeout(const Duration(seconds: 10));
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<AppUser?> getUserByNickname(String nickname) async {
    final normalizedNickname = _normalizeNickname(nickname);
    if (normalizedNickname.isEmpty) return null;

    final query = await _users
      .where('nickname', isEqualTo: normalizedNickname)
      .limit(1)
      .get()
      .timeout(const Duration(seconds: 10));

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return AppUser.fromMap(doc.data());
  }

  /// Busca un usuario por email (útil para invitar/añadir admins).
  ///
  /// Nota: depende de que el campo `email` exista en `/users/{uid}`.
  Future<AppUser?> getUserByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;

    // Intentamos primero con email normalizado y, si no hay match,
    // probamos el valor original por compatibilidad.
    final candidates = <String>{
      trimmed.toLowerCase(),
      trimmed,
    }.toList(growable: false);

    for (final candidate in candidates) {
      final query = await _users
          .where('email', isEqualTo: candidate)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      if (query.docs.isNotEmpty) {
        return AppUser.fromMap(query.docs.first.data());
      }
    }
    return null;
  }

  @override
  Future<bool> userExists(String uid) async {
    final doc = await _users.doc(uid).get().timeout(const Duration(seconds: 10));
    return doc.exists;
  }

  // ── Unicidad de nickname ────────────────────────────────────────────────────

  @override
  Future<bool> isNicknameAvailable(String nickname) async {
    final normalizedNickname = _normalizeNickname(nickname);
    final query = await _users
        .where('nickname', isEqualTo: normalizedNickname)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));
    return query.docs.isEmpty;
  }

  String _normalizeNickname(String nickname) => nickname.trim().toLowerCase();
}
