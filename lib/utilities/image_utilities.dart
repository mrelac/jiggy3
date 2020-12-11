import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;
import 'package:image_cropper/image_cropper.dart';


class ImageUtils {

  static Future<Uint8List> imageAssetToImageBytes(String assetLocation) async {
      return (await rootBundle.load(assetLocation)).buffer.asUint8List();
  }

  static Future<Image> createImage(String name, Uint8List byteData) async {
    String imageLocation = createLocationFromName(name);
    Image memImage = Image.memory(byteData);
    Size imageSize = await getImageSize(memImage);
    File imageFile = new File(imageLocation);
    await imageFile.writeAsBytes(byteData);

    return Image.file(imageFile, width: imageSize.width, height: imageSize.height);
  }

  static Uint8List getThumbFromBig(Uint8List jpgBytesBig) {
    return resizeBytes(jpgBytesBig, 120);
  }

  static Future<Image> createImageFromFile(String name, File file) async {
    return await createImage(name, await file.readAsBytes());
  }

  static Image imageFromBase64String(String base64String) {
    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.fill,
      );
  }

  static Uint8List dataFromBase64String(String base64String) {
    return base64Decode(base64String);
  }

  static String base64String(Uint8List data) {
    return base64Encode(data);
  }

  /// Translates imglib Image to material Image using encodeJpg.
  static MemoryImage imglibToImage(imglib.Image libImage) {
    Image image = Image.memory(imglib.encodeJpg(libImage));
    return image.image;
  }

  static MemoryImage asImageMemory(Image image) {
    if (image.runtimeType != MemoryImage) {
      throw Exception('image input parameter is not of expected type MemoryImage');
    }
    return image.image;
  }

  static imglib.Image toImglibFromBytes(Uint8List bytes) {
    imglib.Image i = imglib.decodeImage(bytes);
    return imglib.decodeImage(bytes);
  }
  
  static Future<imglib.Image> toImgLib(Image image) async {
    Uint8List bytes = await getImageBytes(image);
    
    return toImglibFromBytes(bytes);
  }


  // This appears to corrupt the image. Don't know why. So don't resize.
  // NOTE: MAYBE DON'T SPECIFY BOTH WIDTH AND HEIGHT?
  
  // By convention, any Uint8List is a jpg byte stream. This convention allows
  //   us to encode/decode without having to check image type first.
  static Uint8List resizeBytes(Uint8List bytes, double width, [double height]) {
    imglib.Image libImage = imglib.copyResize(imglib.decodeJpg(bytes),
                                              width: width.floor(),
                                              height: height?.floor());
    return imglibToImage(libImage).bytes;
  }

  static Future<Image> fitImageBytesToDevice(
      String name, Uint8List imageBytes, double width, double height,
      Size deviceSize) async {
    Size original = Size(width, height);
    double newHeight;
    double newWidth;

    if (isPortrait(original)) {
      newHeight = max(deviceSize.height, deviceSize.width);
      newWidth = min(deviceSize.height, deviceSize.width);
    } else {
      newHeight = min(deviceSize.height, deviceSize.width);
      newWidth = max(deviceSize.height, deviceSize.width);
    }
    Uint8List newBytes = resizeBytes(imageBytes, newWidth, newHeight);
    File newImageFile = File(createLocationFromName(name));
    await newImageFile.writeAsBytes(newBytes);
    return Image.file(newImageFile, width: newWidth, height: newHeight);
  }

  static Future<Image> fitImageToDevice(String name, Image image, Size deviceSize) async {
    Uint8List imageBytes = await getImageBytes(image);
    return fitImageBytesToDevice(name,imageBytes, image.width, image.height,
                                     deviceSize);
  }

  static bool isPortrait(Size imageSize) {
    return imageSize.height > imageSize.width;
  }

  static Future<Size> getFileImageSize(FileImage image) {
    Completer<Size> completer = Completer();
    image.resolve(ImageConfiguration()).addListener(
        ImageStreamListener(
                (ImageInfo imageInfo, bool synchronousCall) {
              Size size = Size(
                  imageInfo.image.width.toDouble(),
                  imageInfo.image.height.toDouble());
              completer.complete(size);
            }));
    
    return completer.future;
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

  static File getImageFile(Image image) {
    return (image.image as FileImage).file;
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

  // Usage: newImage = await ImageUtils.cropImage(newImage);
  /// Returns null if user canceled crop request
  static Future<File> cropImageDialog(File imageFile) async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: CropAspectRatioPreset.values,
    );

    return croppedFile;
  }

  /// name - the name (without extension) that will be the filename
  ///
  /// Returns a String with the fully-qualified image path, the name, and a
  /// .jpg extension.
  @deprecated
  // Moved to jiggy_fileysstem.dart
  static String createLocationFromName(String name) {
    // return '${globals.appImagesDirectory}/$name.jpg';
  }

  /// name - the name (without extension) that will be the filename
  ///
  /// Returns a String with the fully-qualified image path, the name, and a
  /// .jpg extension.

  //Used temporarily while trying out persisting thumbnail to file system.
  // Since thumbnails are small, we should instead persist them to the db.
  // @deprecated
  // static String createLocationThumbFromName(String name) {
  //   return '${globals.appImagesDirectory}/$name.thumb.jpg';
  // }
}
