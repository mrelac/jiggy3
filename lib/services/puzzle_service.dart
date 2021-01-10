import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as imglib;
import 'package:jiggy3/blocs/puzzle_bloc.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';

import 'image_service.dart';

class PuzzleService {



  // Puzzle Size (from other game, all Landscape):
  // 15 - 5 x 3      1.667
  // 40 - 8 x 5      1.660
  // 77 - 11 x 7     1.571
  // 96 - 12 x 8     1.50
  // 140, 14 x 10    1.40
  // 234, 18 x 13    1.385
  // 336, 21 x 16    1.312
  // 432  24 x 18    1.333

  static Future<void> splitImageIntoPieces2(Puzzle puzzle, BuildContext context) {
    PuzzleBloc puzzleBloc = BlocProvider.of<PuzzleBloc>(context);



  }


  /// Image to tablet orientation notes:
  /// TabletOrientation: landscape = VERTICAL_PIECES_STRIP
  /// TabletOrientation: Portrait = HORIZONTAL_PIECES_STRIP
  /// 1. Resize Portrait image height to: max(Tablet Height, tablet width) - HORIZONTAL_PIECES_STRIP height (1024 - 80)
  ///    Resize Portrait image width to: min(Tablet height, tablet width) (768)
  ///    Resize Landscape image height to: min(Tablet height, tablet width) (768)
  ///    Resize Landscape image width to: max(Tablet height, tablet width) - VERTICAL_PIECES_STRIP height (1024 - 80)
  // FIXME: This doesn't honor numPieces, instead creating a different number of pieces.
  static Future<List<PuzzlePiece>> splitImageIntoPieces({
    int puzzleId,
      Image image, double imageWidth, double imageHeight, int numPieces, Size deviceSize}) async {
    var pieces = <PuzzlePiece>[];







    // Resize original image as above. FIXME This should be done in onPlayPressed!!
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




    // Example stream
    // Stream<int> timedCounter(Duration interval, [int maxCount]) async* {
    //   int i = 0;
    //   while (true) {
    //     await Future.delayed(interval);
    //     yield i++;
    //     if (i == maxCount) break;
    //   }
    // }








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

          // FIXME instead of adding to parts, consider adding the small images to the puzzleSink!!!
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
    // List<Image> output = List<Image>();
    // for (var img in parts) {
    //   pieces.add(PuzzlePiece(image: Image.memory(imglib.encodeJpg(img))));
    //   pieces.add(PuzzlePiece(puzzleId: puzzleId,
    //   ))
    //   Uint8List uu = imglib.encodeJpg(img);
    //
    // }

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
