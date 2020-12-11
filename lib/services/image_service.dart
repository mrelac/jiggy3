import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;


class ImageService {

  // By convention, bytes must be a jpg byte stream. This convention allows
  // us to encode/decode without having to check image type first.
  static Uint8List resizeBytes(Uint8List bytes, double width, [double height]) {
    imglib.Image libImage = imglib.copyResize(imglib.decodeJpg(bytes),
        width: width.floor(),
        height: height?.floor());
    return imglibToImage(libImage).bytes;
  }

  /// Translates imglib Image to material Image using encodeJpg.
  static MemoryImage imglibToImage(imglib.Image libImage) {
    Image image = Image.memory(imglib.encodeJpg(libImage));
    return image.image;
  }

}