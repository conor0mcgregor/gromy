import 'package:image_picker/image_picker.dart';

abstract interface class UserStorageService {
  /// Sube la imagen de perfil asociada al [uid]
  /// y devuelve la URL pública de descarga.
  Future<String> uploadProfileImage({
    required String uid,
    required XFile image,
  });

  /// Elimina la imagen de perfil asociada a [uid] si existe.
  Future<void> deleteProfileImage(String uid);
}

class UserStorageException implements Exception {
  const UserStorageException(this.message);
  final String message;

  @override
  String toString() => 'UserStorageException: $message';
}
