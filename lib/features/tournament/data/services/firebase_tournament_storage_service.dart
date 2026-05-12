import 'dart:developer' as developer;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:image_picker/image_picker.dart';

import 'image_file_probe_stub.dart'
    if (dart.library.io) 'image_file_probe_io.dart';
import 'tournament_storage_service.dart';

/// Implementación de [TournamentStorageService] usando Firebase Storage.
///
/// Las imágenes se guardan en la ruta:
///   `tournament_covers/<tournamentId>.jpg`
///
/// SRP: esta clase sólo gestiona el ciclo de vida de las imágenes en Storage.
/// DIP: los consumidores dependen de [TournamentStorageService], no de esta clase.
class FirebaseTournamentStorageService implements TournamentStorageService {
  FirebaseTournamentStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const String _coverFolder = 'tournament_covers';

  /// Referencia al archivo de portada del torneo.
  Reference _coverRef(String tournamentId) =>
      _storage.ref('$_coverFolder/$tournamentId.jpg');

  /// Content-Type HTTP coherente con [XFile.mimeType] cuando viene del picker.
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

  @override
  Future<String> uploadCoverImage({
    required String tournamentId,
    required String ownerUid,
    required XFile image,
  }) async {
    final bucket = _storage.app.options.storageBucket ?? '(bucket null)';
    final pathForLog = image.path.isEmpty ? '(path vacío)' : image.path;
    final appName = _storage.app.name;
    final projectId = _storage.app.options.projectId;

    try {
      final probe = await probeXFile(image);
      // putData(readAsBytes) evita depender de rutas locales válidas para
      // dart:io File (web, algunos content:// en Android, etc.). El formulario
      // ya demuestra que readAsBytes funciona al generar la vista previa.
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw const StorageUploadException(
          'La imagen no tiene datos (0 bytes). Elige otra foto e inténtalo de nuevo.',
        );
      }

      final contentType = _contentTypeFor(image);
      final ref = _coverRef(tournamentId);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'ownerUid': ownerUid,
          'kind': 'tournament_cover',
          'tournamentId': tournamentId,
        },
      );

      if (kDebugMode) {
        developer.log(
          'Starting tournament cover upload | app=$appName projectId=$projectId '
          'bucket=$bucket storagePath=${ref.fullPath} tournamentId=$tournamentId '
          'ownerUid=$ownerUid xFile.path=$pathForLog '
          'xFile.exists=${probe.existsForLog} statSize=${probe.statSizeForLog} '
          'bytes=${bytes.length} xFile.mimeType=${image.mimeType ?? "(null)"} '
          'contentType=$contentType',
          name: 'TournamentStorage',
        );
      }

      final snapshot = await ref.putData(bytes, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      if (kDebugMode) {
        developer.log(
          'Tournament cover upload completed | bucket=$bucket '
          'storagePath=${snapshot.ref.fullPath} bytesTransferred=${snapshot.bytesTransferred} '
          'totalBytes=${snapshot.totalBytes}',
          name: 'TournamentStorage',
        );
      }
      return downloadUrl;
    } on StorageUploadException {
      rethrow;
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'FirebaseException uploading tournament cover | code=${e.code} '
          'message=${e.message ?? "(null)"} plugin=${e.plugin} '
          'bucket=$bucket tournamentId=$tournamentId ownerUid=$ownerUid '
          'xFile.path=$pathForLog',
          name: 'TournamentStorage',
          error: e,
          stackTrace: st,
        );
      }
      throw StorageUploadException(
        'Firebase Storage [${e.code}]: ${e.message ?? "sin mensaje del servidor"}',
        cause: e,
      );
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Unexpected error uploading tournament cover | app=$appName '
          'projectId=$projectId bucket=$bucket tournamentId=$tournamentId '
          'ownerUid=$ownerUid xFile.path=$pathForLog',
          name: 'TournamentStorage',
          error: e,
          stackTrace: st,
        );
      }
      throw StorageUploadException(
        'No se pudo leer o subir la imagen: $e',
        cause: e,
      );
    }
  }

  @override
  Future<void> deleteCoverImage(String tournamentId) async {
    try {
      await _coverRef(tournamentId).delete();
    } on FirebaseException catch (e) {
      // Si el objeto no existe (object-not-found) lo ignoramos.
      if (e.code == 'object-not-found') return;
      rethrow;
    }
  }
}
