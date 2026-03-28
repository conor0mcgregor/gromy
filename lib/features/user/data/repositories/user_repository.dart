import '../models/app_user.dart';

class NicknameAlreadyInUseException implements Exception {
  const NicknameAlreadyInUseException();
}

/// Contrato abstracto del repositorio de usuarios (DIP de SOLID).
///
/// Toda la lógica de negocio depende de esta interfaz, nunca de Firestore
/// directamente, lo que facilita tests y futuros cambios de backend.
abstract interface class UserRepository {
  /// Crea o sobreescribe el documento del usuario en Firestore.
  Future<void> createUser(AppUser user);

  /// Devuelve el usuario con [uid] o `null` si no existe.
  Future<AppUser?> getUser(String uid);

  /// Comprueba si ya existe un documento para [uid].
  Future<bool> userExists(String uid);

  /// Devuelve `true` si ningún usuario tiene el [nickname] dado.
  Future<bool> isNicknameAvailable(String nickname);
}
