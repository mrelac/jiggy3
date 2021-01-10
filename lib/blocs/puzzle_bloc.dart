import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';

// FIXME FIXME FIXME This class needs work

class PuzzleBloc extends Cubit<Puzzle> {
  PuzzleBloc(this._puzzle) : super(_puzzle) {
    getPuzzlePieces();
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

  // /// Crop puzzle image. Returns null if crop was canceled by the user; else:
  // /// - Creates a new, cropped image from the original image
  // /// - Uses the original name suffixed numerically to make the name unique
  // /// - Inserts the cropped puzzle into the database
  // /// - returns the new puzzle
  // Future<Puzzle> cropImageAndCreateNewPuzzle(Puzzle puzzle) async {
  //   File croppedFile = await ImageService.cropImageDialog(
  //       File(puzzle.imageLocation));
  //   if (croppedFile == null) {
  //     return null;
  //   }
  //   List<String> excludedNames = ((await Repository.getPuzzles())
  //       .map((p) => p.name)).toList();
  //   String name = Utils.generateUniqueName(puzzle.name, excludedNames);
  //   Puzzle newPuzzle = await Repository.createPuzzle(
  //       name, puzzle.imageLocation);
  //   return newPuzzle;
  // }

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
    getPuzzle();
  }

  Future<Puzzle> createPuzzle(
      String name, String imageLocation) async {
    return await Repository.createPuzzle(name, imageLocation);
  }

  Future<void> deletePuzzleImage(String location) async {
    await Repository.deletePuzzleImage(location);
  }

  Future<void> getPuzzle() async {
    _puzzle = await Repository.getPuzzleById(_puzzle.id);
    if (_pieces == null) {
      _pieces = await Repository.getPuzzlePieces(_puzzle.id);
    }
    _puzzle.pieces.addAll(_pieces);
    _puzzlesStream.sink.add(_puzzle);
  }

  Future<void> getPuzzlePieces() async {
    _pieces = await Repository.getPuzzlePieces(_puzzle.id);
    _puzzlePiecesStream.sink.add(_pieces);
  }

  Future<void> addPuzzlePiece(PuzzlePiece piece) async {
    piece = await Repository.insertPuzzlePiece(piece);
    _pieces.add(piece);
    getPuzzlePieces();
  }

  Future<void> updatePuzzlePieceLocked(int puzzlePieceId, bool isLocked) async {
    await Repository.updatePuzzlePieceLocked(puzzlePieceId, isLocked);
    _pieces
        .where((p) => p.id == puzzlePieceId)
        .map((p2) => p2.locked = isLocked);
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
