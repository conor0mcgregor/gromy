import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamStorageService  ·  Servicio de almacenamiento de imágenes de equipo
//
//  Gestiona la subida y eliminación de imágenes de perfil de equipo
//  en Firebase Storage.
//
//  Ruta de almacenamiento: team_photos/<teamId>.jpg
//
//  Sigue el mismo patrón que FirebaseTournamentStorageService.
//  SRP: solo gestiona el ciclo de vida de las imágenes de equipo en Storage.
// ─────────────────────────────────────────────────────────────────────────────

class TeamStorageService {
  TeamStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const String _photoFolder = 'team_photos';

  /// Referencia al archivo de foto del equipo.
  Reference _photoRef(String teamId) =>
      _storage.ref('$_photoFolder/$teamId.jpg');

  /// Sube la imagen de perfil del equipo y devuelve la URL de descarga.
  ///
  /// Si [imageFile] es un XFile (de image_picker), se sube a Firebase Storage.
  /// Devuelve la URL pública de descarga.
  Future<String> uploadTeamPhoto({
    required String teamId,
    required XFile imageFile,
  }) async {
    try {
      final ref = _photoRef(teamId);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Usamos putFile en plataformas nativas; putData como fallback web.
      late final TaskSnapshot snapshot;
      if (identical(0, 0.0)) {
        // Web: lee bytes
        final bytes = await imageFile.readAsBytes();
        snapshot = await ref.putData(bytes, metadata);
      } else {
        snapshot = await ref.putFile(File(imageFile.path), metadata);
      }

      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw TeamStorageException(
        'Firebase Storage error [${e.code}]: ${e.message}',
      );
    } catch (e) {
      throw TeamStorageException(
        'Error inesperado al subir la foto del equipo: $e',
      );
    }
  }

  /// Elimina la foto de perfil del equipo si existe.
  Future<void> deleteTeamPhoto(String teamId) async {
    try {
      await _photoRef(teamId).delete();
    } on FirebaseException catch (e) {
      // Si el objeto no existe (object-not-found) lo ignoramos.
      if (e.code == 'object-not-found') return;
      rethrow;
    }
  }
}

/// Excepción semántica para errores de subida de foto de equipo.
class TeamStorageException implements Exception {
  const TeamStorageException(this.message);
  final String message;

  @override
  String toString() => 'TeamStorageException: $message';
}
