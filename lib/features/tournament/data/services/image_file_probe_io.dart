import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'image_file_probe_stub.dart';

Future<ImageFileProbe> probeXFile(XFile image) async {
  final path = image.path.trim();
  if (path.isEmpty) {
    return const ImageFileProbe(exists: false);
  }

  try {
    final file = File(path);
    final exists = await file.exists();
    final size = exists ? await file.length() : null;
    return ImageFileProbe(exists: exists, statSize: size);
  } catch (_) {
    return const ImageFileProbe();
  }
}
