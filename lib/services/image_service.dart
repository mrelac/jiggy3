import 'dart:async';
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

  /// Return image bytes for any type of image: AssetImage, FileImage,
  /// NetworkImage, or MemoryImage.
  static Future<Uint8List> getImageBytes(Image image) async {
    Uint8List bytes;

    if (image == null) {
      return null;
    }
    switch (image.image.runtimeType) {
      case AssetImage:
        {
          AssetImage ai = image.image as AssetImage;
          ByteData bd = await rootBundle.load(ai.assetName);
          final buffer = bd.buffer;
          bytes = buffer.asUint8List();
          break;
        }

      case FileImage:
        {
          FileImage fi = image.image as FileImage;
          bytes = fi.file.readAsBytesSync();
          break;
        }

      case NetworkImage:
        {
          NetworkImage ni = image.image as NetworkImage;
          bytes =
              (await NetworkAssetBundle(Uri.parse(ni.url)).load(ni.url)).buffer
                  .asUint8List();
          break;
        }

      case MemoryImage:
        {
          MemoryImage mi = image.image as MemoryImage;
          bytes = mi.bytes;
          break;
        }

      default:
        {
          print(
              'imageToBytes(): Unknown Image type ${image.image.runtimeType}');
          break;
        }
    }

    return bytes;
  }

  static Future<Size> getImageSize(Image image) {
    Completer<Size> completer = Completer();
    image.image.resolve(ImageConfiguration()).addListener(
        ImageStreamListener(
                (ImageInfo imageInfo, bool synchronousCall) {
              Size size = Size(
                  imageInfo.image.width.toDouble(),
                  imageInfo.image.height.toDouble());
              completer.complete(size);
            }));

    return completer.future;
  }

  // By convention, bytes must be a jpg byte stream. This convention allows
  // us to encode/decode without having to check image type first.
  static Uint8List resizeBytes(Uint8List bytes, double width, [double height]) {
    imglib.Image libImage = imglib.copyResize(imglib.decodeJpg(bytes),
        width: width.floor(), height: height?.floor());
    return imglibToImage(libImage).bytes;
  }

  static bool isPortrait(Size imageSize) {
    return imageSize.height > imageSize.width;
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
