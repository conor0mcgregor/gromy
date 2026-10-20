import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalTournamentImageService
//
//  Gestiona la selección, persistencia y eliminación de imágenes de portada
//  de torneos locales.
//
//  Estrategia de persistencia:
//    - Las imágenes se copian a un directorio propio de la app
//      (applicationDocumentsDirectory/local_tournament_covers/)
//    - Se almacena la ruta de este archivo permanente (no la ruta temporal)
//    - Se redimensionan a un máximo de 1024px para ahorrar espacio
//
//  Independencia de Firebase: ninguna imagen se sube a Storage.
// ─────────────────────────────────────────────────────────────────────────────

class LocalTournamentImageService {
  static const _coverDir = 'local_tournament_covers';
  static const _maxDimension = 1024;
  static const _jpegQuality = 85;

  final ImagePicker _picker;

  LocalTournamentImageService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  /// Selecciona una imagen de la galería sin guardarla aún (para vista previa).
  Future<XFile?> pickImageFile() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxDimension.toDouble(),
        maxHeight: _maxDimension.toDouble(),
        imageQuality: _jpegQuality,
      );
    } catch (e) {
      debugPrint('LocalTournamentImageService: error picking image: $e');
      return null;
    }
  }

  /// Guarda de forma permanente una imagen previamente seleccionada.
  Future<String?> savePickedImage(XFile file, String tournamentId) async {
    return _persistImage(file, tournamentId);
  }

  /// Abre el selector de imágenes y guarda la imagen en el directorio permanente.
  /// Devuelve la ruta del archivo guardado, o null si el usuario cancela o hay error.
  Future<String?> pickAndSaveCoverImage({
    required String tournamentId,
  }) async {
    final picked = await pickImageFile();
    if (picked == null) return null;
    return _persistImage(picked, tournamentId);
  }

  /// Copia un XFile al directorio permanente de portadas.
  Future<String?> _persistImage(XFile xFile, String tournamentId) async {
    try {
      final dir = await _getCoverDirectory();
      final ext = path.extension(xFile.name).isNotEmpty
          ? path.extension(xFile.name)
          : '.jpg';
      final fileName = 'cover_${tournamentId}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = path.join(dir.path, fileName);

      final bytes = await xFile.readAsBytes();
      await File(destPath).writeAsBytes(bytes);
      return destPath;
    } catch (e) {
      debugPrint('LocalTournamentImageService: error persisting image: $e');
      return null;
    }
  }

  /// Elimina la imagen de portada del torneo.
  Future<void> deleteCoverImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('LocalTournamentImageService: error deleting image: $e');
    }
  }

  /// Verifica si una imagen en la ruta dada aún existe.
  Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;
    try {
      return File(imagePath).exists();
    } catch (_) {
      return false;
    }
  }

  /// Devuelve el directorio de portadas, creándolo si no existe.
  Future<Directory> _getCoverDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory(path.join(appDir.path, _coverDir));
    if (!coverDir.existsSync()) {
      await coverDir.create(recursive: true);
    }
    return coverDir;
  }
}
