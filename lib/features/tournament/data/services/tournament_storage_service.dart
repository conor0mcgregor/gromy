import 'package:image_picker/image_picker.dart';

/// Contrato para subir activos multimedia de torneos a un servicio de
/// almacenamiento remoto (p.ej. Firebase Storage).
///
/// Seguimos ISP: esta interfaz es independiente de [TournamentRepository] para
/// que los consumidores que sólo necesitan una de las dos no dependan de la
/// otra.
abstract interface class TournamentStorageService {
  /// Sube la imagen de portada [image] asociada al torneo con [tournamentId]
  /// y devuelve la URL pública de descarga.
  ///
  /// Lanza [StorageUploadException] si la operación falla.
  Future<String> uploadCoverImage({
    required String tournamentId,
    required XFile image,
  });

  /// Elimina la imagen de portada asociada a [tournamentId] si existe.
  /// No lanza error si la imagen no existe.
  Future<void> deleteCoverImage(String tournamentId);
}

/// Excepción semántica para errores de subida a Storage.
class StorageUploadException implements Exception {
  const StorageUploadException(this.message);
  final String message;

  @override
  String toString() => 'StorageUploadException: $message';
}
