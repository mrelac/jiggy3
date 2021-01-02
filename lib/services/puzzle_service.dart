import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:jiggy3/models/puzzle_piece.dart';

import 'image_service.dart';

class PuzzleService {
  // FIXME: This doesn't honor numPieces, instead creating a different number of pieces.
  static Future<List<PuzzlePiece>> splitImageIntoPieces({
      Image image, double imageWidth, double imageHeight, int numPieces, Size deviceSize}) async {
    var pieces = <PuzzlePiece>[];

    Uint8List largeImageBytes = await ImageService.getImageBytes(image);
    Size largeImageSize = await ImageService.getImageSize(image);
    imglib.Image imglibOriginalBytes = imglib.decodeImage(largeImageBytes);

    double newHeight;
    double newWidth;
    if (ImageService.isPortrait(largeImageSize)) {
      newHeight = max(deviceSize.height, deviceSize.width);
      newWidth = min(deviceSize.height, deviceSize.width);
    } else {
      newHeight = min(deviceSize.height, deviceSize.width);
      newWidth = max(deviceSize.height, deviceSize.width);
    }

    imglib.Image imglibSmallImage = imglib.copyResize(imglibOriginalBytes,
        height: newHeight.toInt(), width: newWidth.toInt());
    Image image2 = Image.memory(imglib.encodeJpg(imglibSmallImage));
    Size smallImageSize = await ImageService.getImageSize(image2);
    Uint8List smallImageBytes = await ImageService.getImageBytes(image2);
    print(
        'TEST: largeImage size = $largeImageSize. byteCount = ${largeImageBytes.length}');
    print(
        'TEST: smallImage size = $smallImageSize. byteCount = ${smallImageBytes.length}');

    int x = 0, y = 0;
    Size colsAndRows =
        _computeNumRowsAndCols(numPieces, imageWidth, imageHeight);
    int numCols = colsAndRows.width.toInt();
    int numRows = colsAndRows.height.toInt();
    int width = (imageWidth / numCols).floor();
    int height = (imageHeight / numRows).floor();
    imglib.Image imglibImage = imglibSmallImage;
    List<imglib.Image> parts = List<imglib.Image>();
    for (int i = 0; i < numRows; i++) {
      for (int j = 0; j < numCols; j++) {
//print('x: $x, y: $y, width: $width, height: $height');
        try {
          parts.add(imglib.copyCrop(imglibImage, x, y, width, height));
        } catch (e) {
          break;
        }
        x += width;
      }
      x = 0;
      y += height;
    }

    // convert image from image package to Image Widget to display
    List<Image> output = List<Image>();
    for (var img in parts) {
      pieces.add(PuzzlePiece(image: Image.memory(imglib.encodeJpg(img))));
    }

    print('Loaded ${pieces.length} pieces. Width: $width, Height: $height');

    return pieces;
  }

  static Size _computeNumRowsAndCols(
      int numPieces, double imageWidth, double imageHeight) {
    double imageAspectRatio = imageWidth / imageHeight;

    // Compute number of cols: sqrt(numPieces * aspectRatio)
    int cols = sqrt(numPieces * imageAspectRatio).floor();

    // Compute number of rows: cols * 1 / aspectRatio
    int rows = (cols * 1 / imageAspectRatio).floor();
    print('Rows = $rows. cols = $cols');
    return Size(cols.toDouble(), rows.toDouble());
  }
}
