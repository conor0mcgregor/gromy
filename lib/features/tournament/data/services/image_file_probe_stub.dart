import 'package:image_picker/image_picker.dart';

class ImageFileProbe {
  const ImageFileProbe({this.exists, this.statSize});

  final bool? exists;
  final int? statSize;

  String get existsForLog => exists == null ? 'not-available' : '$exists';
  String get statSizeForLog => statSize == null ? 'not-available' : '$statSize';
}

Future<ImageFileProbe> probeXFile(XFile image) async {
  return const ImageFileProbe();
}
