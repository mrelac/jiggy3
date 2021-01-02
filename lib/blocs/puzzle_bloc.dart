import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/data/jiggy_filesystem.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/services/image_service.dart';
import 'package:jiggy3/services/utils.dart';
import 'package:jiggy3/utilities/image_utilities.dart';

import 'bloc_provider.dart';

// FIXME FIXME FIXME This class needs work

class PuzzleBloc extends Cubit<Puzzle> {
  PuzzleBloc(this._puzzle) : super(_puzzle) {
    // getPuzzles();
  }

  final Puzzle _puzzle;
  final _puzzlesStream = StreamController<Puzzle>.broadcast();

  Stream<Puzzle> get puzzlesStream => _puzzlesStream.stream;

  void dispose() {
    _puzzlesStream.close();
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
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        imageColour: imageColour,
        imageOpacity: imageOpacity,
        maxPieces: maxPieces);
  }
}
