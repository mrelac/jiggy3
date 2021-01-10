import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;
import 'package:image_cropper/image_cropper.dart';
import 'package:jiggy3/pages/chooser_page.dart';

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
          bytes = (await NetworkAssetBundle(Uri.parse(ni.url)).load(ni.url))
              .buffer
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
        ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
      Size size = Size(
          imageInfo.image.width.toDouble(), imageInfo.image.height.toDouble());
      completer.complete(size);
    }));

    return completer.future;
  }

  static Future<Size> getImageSizeFromBytes(Uint8List bytes) async {
    return await getImageSize(Image.memory(bytes));
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

  /// Images already seem to be resized to some factor of device size.
  /// Testing asset image sizes reveals:
  ///   - landscape: set resize width to 1024 and resized height is 768
  ///       Inserting puzzle Hallstatt
  ///       Image full: Size(4096.0, 3072.0)
  ///         width  1024 => Size(1024.0, 768.0)
  ///         width   768 => Size(768.0, 576.0)    (BAD)
  ///         height 1024 => Size(1365.0, 1024.0)  (BAD)
  ///         height  768 => Size(1024.0, 768.0)
  ///   - Portrait:  set resize width to  768 and resized height is 1024
  ///       Inserting puzzle Hallstätter See
  ///       Image full: Size(3072.0, 4096.0)
  ///         width  1024 => Size(1024.0, 1365.0)  (BAD)
  ///         width   768 => Size(768.0, 1024.0)
  ///         height 1024 => Size(768.0, 1024.0)
  ///         height  768 => Size(576.0, 768.0)    (BAD)
  ///
  static Future<Uint8List> fitImageBytesToDevice(Uint8List fullBytes) async {
    Size deviceSize = ChooserPage.deviceSize;
    Size bytesSize = await getImageSizeFromBytes(fullBytes);
    int devShortSide = min(deviceSize.width.toInt(), deviceSize.height.toInt());
    int devLongSide = max(deviceSize.width.toInt(), deviceSize.height.toInt());
    int width = isPortrait(bytesSize) ? devShortSide : devLongSide;
    return imglib.encodeJpg(
        imglib.copyResize(imglib.decodeJpg(fullBytes), width: width));
  }

// USED FOR DEBUGGING
// static Future<void> doit(Uint8List fullBytes) async {
//   imglib.Image w1024 = imglib.copyResize(imglib.decodeJpg(fullBytes), width: 1024);
//   imglib.Image w768 = imglib.copyResize(imglib.decodeJpg(fullBytes), width: 768);
//   imglib.Image h1024 = imglib.copyResize(imglib.decodeJpg(fullBytes), height: 1024);
//   imglib.Image h768 = imglib.copyResize(imglib.decodeJpg(fullBytes), height: 768);
//   Size fullBytesSize = await getImageSizeFromBytes(fullBytes);
//   Size w1024Size = await getImageSizeFromBytes(imglibToImage(w1024).bytes);
//   Size w768Size = await getImageSizeFromBytes(imglibToImage(w768).bytes);
//   Size h1024Size = await getImageSizeFromBytes(imglibToImage(h1024).bytes);
//   Size h768Size = await getImageSizeFromBytes(imglibToImage(h768).bytes);
//
//   print('Image full: $fullBytesSize');
//   print('  width  1024 => $w1024Size');
//   print('  width   768 => $w768Size');
//   print('  height 1024 => $h1024Size');
//   print('  height  768 => $h768Size');
//   print(' ');
// }
}
