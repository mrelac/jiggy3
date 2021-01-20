import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';
import 'package:jiggy3/models/rc.dart';
import 'package:jiggy3/services/image_service.dart';
import 'package:jiggy3/services/utils.dart';

import 'package:image/image.dart' as imglib;

// FIXME FIXME FIXME This class needs work

class PuzzleBloc extends Cubit<Puzzle> {
  PuzzleBloc(this._puzzle) : super(_puzzle) {
    loadPuzzlePieces();
  }

  Puzzle _puzzle;
  List<PuzzlePiece> _pieces;

  final _puzzlesStream = StreamController<Puzzle>.broadcast();

  Stream<Puzzle> get puzzlesStream => _puzzlesStream.stream;

  final _puzzlePiecesStream = StreamController<List<PuzzlePiece>>.broadcast();

  Stream<List<PuzzlePiece>> get puzzlePiecesStream =>
      _puzzlePiecesStream.stream;

  void dispose() {
    _puzzlesStream.close();
    _puzzlePiecesStream.close();
  }

  Future<void> updatePuzzle(int id,
      {String name,
      Uint8List thumb,
      String imageLocation,
      double imageWidth,
      double imageHeight,
      Color imageColour,
      double imageOpacity,
      int maxPieces}) async {
    await Repository.updatePuzzle(id,
        name: name,
        thumb: thumb,
        imageLocation: imageLocation,
        imageColour: imageColour,
        imageOpacity: imageOpacity,
        maxPieces: maxPieces);
    loadPuzzle();
  }

  Future<Puzzle> createPuzzle(String name, String imageLocation) async {
    return await Repository.createPuzzle(name, imageLocation);
  }

  Future<void> deletePuzzleImage(String location) async {
    await Repository.deletePuzzleImage(location);
  }

  Future<void> loadPuzzle() async {
    _puzzle = await Repository.getPuzzleById(_puzzle.id);
    await _puzzle.loadImage();
    // FIXME I don't think puzzle needs to contain puzzlePieces. Delete this code?
    if (_pieces == null) {
      _pieces = await Repository.getPuzzlePieces(_puzzle.id);
    }
    _puzzle.pieces.addAll(_pieces);
    _puzzlesStream.sink.add(_puzzle);
  }

  Future<void> loadPuzzlePieces() async {
    _pieces = await Repository.getPuzzlePieces(_puzzle.id);
    if (_pieces.isNotEmpty) {
      _puzzlePiecesStream.sink.add(_pieces);
    }
  }

  Future<void> addPuzzlePiece(PuzzlePiece piece) async {
    piece = await Repository.insertPuzzlePiece(piece);
    _pieces.add(piece);
    loadPuzzlePieces();
  }

  /// The image must have a width and height. maxPieces will be swapped if
  /// image is portrait (default maxpieces orientation is landscape)
  Future<void> splitImageIntoPieces(Puzzle puzzle, RC maxPieces) async {
    Image image = puzzle.image;
    DateTime start = DateTime.now();
    Utils.printDateTime(
        prefix: 'Before INSERTING ${maxPieces.row * maxPieces.col} pieces: ',
        dateFormat: Utils.DEFAULT_TIIME_FORMAT,
        date: start);

    if (image.width < image.height) {
      maxPieces.swap();
      print('image is portrait. Swapped maxPieces: ${maxPieces.toString()}');
    }
    var pieces = <PuzzlePiece>[];
    int width = (image.width / maxPieces.col).floor();
    int height = (image.height / maxPieces.row).floor();
    int x = 0, y = 0;
    imglib.Image imagelib =
        imglib.decodeJpg(await ImageService.getImageBytes(image));
    for (int i = 0; i < maxPieces.row; i++) {
      pieces.clear();
      for (int j = 0; j < maxPieces.col; j++) {
        Uint8List pieceBytes =
            ImageService.copyCrop(imagelib, x, y, width, height);
        PuzzlePiece piece = PuzzlePiece(
            puzzleId: puzzle.id,
            imageBytes: pieceBytes,
            imageWidth: width.toDouble(),
            imageHeight: height.toDouble(),
            row: x,
            col: y,
            maxRow: maxPieces.row,
            maxCol: maxPieces.col);
        pieces.add(piece);
        x += width;
      }
      await Repository.insertPuzzlePieces(pieces);
      x = 0;
      y += height;
    }
    DateTime end = DateTime.now();
    Utils.printDateTime(
        prefix: 'After INSERTING ${pieces.length} pieces: ',
        dateFormat: Utils.DEFAULT_TIIME_FORMAT,
        date: end);
    Duration d = end.difference(start);
    Utils.printDateTime(
        prefix:
            'Total elapsed time: ${d.inMinutes.toStringAsFixed(2)}:${d.inSeconds.toStringAsFixed(2)}',
        dateFormat: Utils.DEFAULT_TIIME_FORMAT);
  }

  Future<void> updatePuzzlePieceLocked(int puzzlePieceId, bool isLocked) async {
    await Repository.updatePuzzlePieceLocked(puzzlePieceId, isLocked);
    _pieces
        .where((p) => p.id == puzzlePieceId)
        .map((p2) => p2.locked = isLocked);
    _puzzlePiecesStream.add(_pieces);
  }

  Future<void> updatePuzzlePiecePlayed(int puzzlePieceId, bool isPlayed) async {
    await Repository.updatePuzzlePiecePlayed(puzzlePieceId, isPlayed);
    _pieces
        .where((p) => p.id == puzzlePieceId)
        .map((p2) => p2.played = isPlayed);
    _puzzlePiecesStream.add(_pieces);
  }

  Future<void> updatePuzzlePiecePosition(
      int puzzlePieceId, int row, int col) async {
    await Repository.updatePuzzlePiecePosition(puzzlePieceId, row, col);
    _pieces.where((p) => p.id == puzzlePieceId).map((p2) {
      p2.row = row;
      p2.col = col;
    });
    _puzzlePiecesStream.add(_pieces);
  }
}
