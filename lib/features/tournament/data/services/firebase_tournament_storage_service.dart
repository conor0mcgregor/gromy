import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  Future<String> uploadCoverImage({
    required String tournamentId,
    required XFile image,
  }) async {
    try {
      final ref = _coverRef(tournamentId);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Usamos putFile en plataformas nativas; putData como fallback web.
      late final TaskSnapshot snapshot;
      if (identical(0, 0.0)) {
        // Web: lee bytes
        final bytes = await image.readAsBytes();
        snapshot = await ref.putData(bytes, metadata);
      } else {
        snapshot = await ref.putFile(File(image.path), metadata);
      }

      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageUploadException(
        'Firebase Storage error [${e.code}]: ${e.message}',
      );
    } catch (e) {
      throw StorageUploadException('Error inesperado al subir la portada: $e');
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
