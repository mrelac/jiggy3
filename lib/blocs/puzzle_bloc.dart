import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as imglib;
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';
import 'package:jiggy3/models/rc.dart';
import 'package:jiggy3/pages/play_page.dart';
import 'package:jiggy3/services/image_service.dart';
import 'package:jiggy3/services/utils.dart';

class PuzzleBloc extends Cubit<Puzzle> {
  PuzzleBloc(this._puzzle) : super(_puzzle);

  Puzzle _puzzle;
  final _puzzlesStream = StreamController<Puzzle>.broadcast();

  Stream<Puzzle> get puzzlesStream => _puzzlesStream.stream;

  final _puzzlePiecesStream = StreamController<List<PuzzlePiece>>.broadcast();

  Stream<List<PuzzlePiece>> get puzzlePiecesStream =>
      _puzzlePiecesStream.stream;

  void dispose() {
    _puzzlesStream.close();
    _puzzlePiecesStream.close();
  }

  Future<void> resetPuzzle(Puzzle puzzle) async {
    int previousMaxPieces = puzzle.maxPieces;
    puzzle.numLocked = 0;
    puzzle.maxRc = RC();
    await Repository.updatePuzzle(puzzle.id,
        maxRc: puzzle.maxRc,
        numLocked: puzzle.numLocked,
        previousMaxPieces: previousMaxPieces);
    await Repository.deletePuzzlePieces(puzzle.id);
  }

  Future<void> updatePuzzle(int id,
      {String name,
      Uint8List thumb,
      String imageLocation,
      double imageWidth,
      double imageHeight,
      Color imageColour,
      double imageOpacity,
      RC maxRc,
      int numLocked,
      int previousMaxPieces}) async {
    await Repository.updatePuzzle(id,
        name: name,
        thumb: thumb,
        imageLocation: imageLocation,
        imageColour: imageColour,
        imageOpacity: imageOpacity,
        maxRc: maxRc,
        numLocked: numLocked,
        previousMaxPieces: previousMaxPieces);
  }

  Future<Puzzle> createPuzzle(String name, String imageLocation) async {
    return await Repository.createPuzzle(name, imageLocation);
  }

  Future<void> deletePuzzleImage(String location) async {
    await Repository.deletePuzzleImage(location);
  }

  Future<void> loadPuzzlePieces() async {
    List<PuzzlePiece> pieces = await Repository.getPuzzlePieces(_puzzle.id);
    if (pieces.isNotEmpty) {
      _puzzlePiecesStream.sink.add(pieces);
    }
  }

  Future<void> updatePuzzlePiece(int id, {bool isLocked, RC last}) async {
    await Repository.updatePuzzlePiece(id, isLocked: isLocked, last: last);
  }

  /// The image must have a width and height. maxPieces will be swapped if
  /// image is portrait (default maxpieces orientation is landscape)
  /// lvCrossAxisSize: e.g. lv element height if lv is horiz; width if lv is vert.
  Future<void> splitImageIntoPieces(Puzzle puzzle, RC maxRc) async {
    Image image = puzzle.image;
    DateTime start = DateTime.now();
    Utils.printDateTime(
        prefix:
            'PuzzleBloc.splitImageIntoPieces(): Before INSERTING ${maxRc.row * maxRc.col} pieces: ',
        dateFormat: Utils.DEFAULT_TIIME_FORMAT,
        date: start);

    if (image.width < image.height) {
      maxRc.swap();
      print(
          'PuzzleBloc.splitImageIntoPieces(): image is portrait. Swapped maxPieces: ${maxRc.toString()}');
    }
    var pieces = <PuzzlePiece>[];

    // IMPORTANT: Subtract listview width (if landscape) / height (if portrait)
    final isImageLandscape = puzzle.image.width > puzzle.image.height;
    final imageWidthAdjusted =
        image.width - (isImageLandscape ? PlayPage.elWidth : 0);
    final imageHeightAdjusted =
        image.height - (isImageLandscape ? 0 : PlayPage.elHeight);
    int width = (imageWidthAdjusted / maxRc.col).ceil();
    int height = (imageHeightAdjusted / maxRc.row).ceil();

    int x = 0, y = 0;
    imglib.Image imagelib =
        imglib.decodeJpg(await ImageService.getImageBytes(image));

    // Do the same thing that BoxFit.fill does:
    // Crop the image to account for listview element width.
    imagelib = imglib.copyResize(imagelib,
        width: imageWidthAdjusted.toInt(), height: imageHeightAdjusted.toInt());

    for (int r = 0; r < maxRc.row; r++) {
      pieces.clear();
      for (int c = 0; c < maxRc.col; c++) {
        Uint8List pieceBytes =
            ImageService.copyCrop(imagelib, x, y, width, height);
        PuzzlePiece piece = PuzzlePiece(
          puzzleId: puzzle.id,
          imageBytes: pieceBytes,
          imageWidth: width.toDouble(),
          imageHeight: height.toDouble(),
          home: RC(row: r, col: c),
        );
        pieces.add(piece);
        x += width;
      }
      await Repository.insertPuzzlePieces(pieces);
      x = 0;
      y += height;
    }
    DateTime end = DateTime.now();
    Utils.printDateTime(
        prefix:
            'PuzzleBloc.splitImageIntoPieces(): After INSERTING ${pieces.length} pieces: ',
        dateFormat: Utils.DEFAULT_TIIME_FORMAT,
        date: end);
    Duration d = end.difference(start);
    Utils.printDateTime(
        prefix:
            'PuzzleBloc.splitImageIntoPieces(): Total elapsed time: ${d.inMinutes.toStringAsFixed(2)}:${d.inSeconds.toStringAsFixed(2)}',
        dateFormat: Utils.DEFAULT_TIIME_FORMAT);
  }
}
