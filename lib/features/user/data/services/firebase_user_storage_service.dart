import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'user_storage_service.dart';

class FirebaseUserStorageService implements UserStorageService {
  FirebaseUserStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  static const String _folder = 'profile_images';

  Reference _profileRef(String uid) => _storage.ref('$_folder/$uid.jpg');

  @override
  Future<String> uploadProfileImage({
    required String uid,
    required XFile image,
  }) async {
    try {
      final ref = _profileRef(uid);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      late final TaskSnapshot snapshot;
      if (identical(0, 0.0)) {
        // Web
        final bytes = await image.readAsBytes();
        snapshot = await ref.putData(bytes, metadata);
      } else {
        // Native
        snapshot = await ref.putFile(File(image.path), metadata);
      }

      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw UserStorageException('Firebase Storage error [${e.code}]: ${e.message}');
    } catch (e) {
      throw UserStorageException('Error inesperado al subir foto: $e');
    }
  }

  @override
  Future<void> deleteProfileImage(String uid) async {
    try {
      await _profileRef(uid).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      rethrow;
    }
  }
}
