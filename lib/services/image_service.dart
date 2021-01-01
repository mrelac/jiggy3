import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;
import 'package:image_cropper/image_cropper.dart';

class ImageService {
  // Usage: newImage = await ImageUtils.cropImage(newImage);
  /// Returns null if user canceled crop request
  static Future<File> cropImageDialog(File imageFile) async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: CropAspectRatioPreset.values,
    );
    return croppedFile;
  }

  // By convention, bytes must be a jpg byte stream. This convention allows
  // us to encode/decode without having to check image type first.
  static Uint8List resizeBytes(Uint8List bytes, double width, [double height]) {
    imglib.Image libImage = imglib.copyResize(imglib.decodeJpg(bytes),
        width: width.floor(), height: height?.floor());
    return imglibToImage(libImage).bytes;
  }

  /// Translates imglib Image to material Image using encodeJpg.
  static MemoryImage imglibToImage(imglib.Image libImage) {
    Image image = Image.memory(imglib.encodeJpg(libImage));
    return image.image;
  }

  /// Read asset ("asset"), network ("http"), or file ("/") asset bytes,
  /// depending on what location starts with
  static Future<Uint8List> readImageBytesFromLocation(String location) async {
    Uint8List fullBytes;
    if (location.startsWith("assets")) {
      fullBytes = (await rootBundle.load(location)).buffer.asUint8List();
    } else if (location.startsWith("http")) {
      fullBytes = (await NetworkAssetBundle(Uri.parse(location)).load(location))
          .buffer
          .asUint8List();
    } else if (location.startsWith("/")) {
      fullBytes = await File(location).readAsBytes();
    } else {
      throw Exception('Unsupported image path $location');
    }
    return fullBytes;
  }
}
