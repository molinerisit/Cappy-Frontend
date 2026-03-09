import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressService {
  static Future<File> compressForUpload(
    File imageFile, {
    int quality = 80,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}${Platform.pathSeparator}upload_${DateTime.now().microsecondsSinceEpoch}.jpg';

      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        return imageFile;
      }

      final compressedFile = File(compressedXFile.path);
      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();

      if (compressedSize >= originalSize) {
        return imageFile;
      }

      final reduction = ((1 - (compressedSize / originalSize)) * 100)
          .toStringAsFixed(1);
      debugPrint(
        'Image compression: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB '
        '-> ${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB '
        '($reduction%)',
      );

      return compressedFile;
    } catch (error) {
      debugPrint('Image compression skipped: $error');
      return imageFile;
    }
  }
}
