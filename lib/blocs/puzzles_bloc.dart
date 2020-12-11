import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/data/jiggy_filesystem.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/utilities/image_utilities.dart';

import 'bloc_provider.dart';


class PuzzlesBloc extends Cubit<List<Puzzle>> implements BlocBase {
  PuzzlesBloc() : super(<Puzzle>[]) {
    // getPuzzles();
  }

  final _puzzlesStream = StreamController<List<Puzzle>>.broadcast();

  Stream<List<Puzzle>> get puzzlesStream => _puzzlesStream.stream;

  // void addPuzzle(Puzzle puzzle) => _puzzlesStream.sink.add([puzzle]);
  // void addPuzzle(String name, Uint8List byteData) async {
  //   Puzzle puzzle;
  //
  //   // - Add full image to filesystem(fqImageName, Uint8List bytes => JiggyFilesystem.saveAssetImage(String fqImageName, String assetLocation,
  //   // - Add image details to database
  //   //   - Create thumb from Uint8List bytes
  //   //   - Create Puzzle(thumb, imageLocation, imageWidth, imageHeight, imageColour, imageOpacity, maxPieces)
  //   // - Refresh stream
  //
  //   // See ChooserPage._addNewPuzzle() for Image and Puzzle creation below.
  //   Image image = await Repository.createImage(name, byteData);
  //
  //   // See ChooserPage._createPuzzle().
  //
  //
  //
  //   _puzzlesStream.sink.add([puzzle]);
  // }

  // Future<void> clearAllDeleteFlags() async {
  //   List<Puzzle> puzzles = await Repository.getEditablePuzzles();
  //   final newPuzzles = <Puzzle>[];
  //   puzzles.forEach((a) => newPuzzles.add(Puzzle(id: a.id, label: a.label)));
  //   _puzzlesStream.sink.add(newPuzzles);
  // }

  // Future<void> setShouldDelete(Puzzle puzzle, bool shouldDelete) async {
  //   List<Puzzle> puzzles = await Repository.getEditablePuzzles();
  //   final newPuzzles = <Puzzle>[];
  //   for (Puzzle a in puzzles) {
  //     if (a.id == puzzle.id) {
  //       newPuzzles
  //           .add(Puzzle(id: a.id, label: a.label, shouldDelete: shouldDelete));
  //     } else {
  //       newPuzzles.add(a);
  //     }
  //   }
  //   _puzzlesStream.sink.add(newPuzzles);
  // }

  // void getPuzzles() async {
  //   final puzzles = <Puzzle>[];
  //   puzzles.add(await Repository.getPuzzleSaved());
  //   puzzles.add(await Repository.getPuzzleAll());
  //   puzzles.addAll(await Repository.getEditablePuzzles());
  //   _puzzlesStream.sink.add(puzzles);
  // }

  void editPuzzleName(Puzzle puzzle) {
    print('PuzzlesBloc: editing puzzle name for puzzle $puzzle');
  }

  // All stream controllers you create should be closed within this function
  @override
  void dispose() {
    _puzzlesStream.close();
  }
}
