import 'dart:developer' as developer;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
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

  static String _contentTypeFor(XFile image) {
    final mime = image.mimeType?.toLowerCase().trim();
    if (mime != null &&
        mime.startsWith('image/') &&
        mime.length > 6 &&
        mime != 'image/*') {
      return mime;
    }
    return 'image/jpeg';
  }

  /// Sube la imagen de perfil del equipo y devuelve la URL de descarga.
  ///
  /// Si [imageFile] es un XFile (de image_picker), se sube a Firebase Storage.
  /// Devuelve la URL pública de descarga.
  Future<String> uploadTeamPhoto({
    required String teamId,
    required XFile imageFile,
  }) async {
    final bucket = _storage.app.options.storageBucket ?? '(bucket null)';
    final pathForLog =
        imageFile.path.isEmpty ? '(path vacío)' : imageFile.path;

    try {
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        throw const TeamStorageException(
          'La imagen no tiene datos (0 bytes). Elige otra foto e inténtalo de nuevo.',
        );
      }

      final contentType = _contentTypeFor(imageFile);
      final ref = _photoRef(teamId);
      final metadata = SettableMetadata(contentType: contentType);

      if (kDebugMode) {
        developer.log(
          'Subida foto equipo: teamId=$teamId bytes=${bytes.length} '
          'contentType=$contentType mimeType=${imageFile.mimeType} bucket=$bucket '
          'xFile.path=$pathForLog',
          name: 'TeamStorage',
        );
      }

      final snapshot = await ref.putData(bytes, metadata);
      return await snapshot.ref.getDownloadURL();
    } on TeamStorageException {
      rethrow;
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'FirebaseException en subida foto equipo: code=${e.code} message=${e.message}',
          name: 'TeamStorage',
          error: e,
          stackTrace: st,
        );
      }
      throw TeamStorageException(
        'Firebase Storage [${e.code}]: ${e.message ?? "sin mensaje del servidor"}',
        cause: e,
      );
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Error inesperado subiendo foto equipo: bucket=$bucket path=$pathForLog',
          name: 'TeamStorage',
          error: e,
          stackTrace: st,
        );
      }
      throw TeamStorageException(
        'No se pudo leer o subir la imagen: $e',
        cause: e,
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
  const TeamStorageException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'TeamStorageException: $message';
}
