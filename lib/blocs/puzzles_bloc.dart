import 'dart:async';

import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle.dart';

import 'bloc_provider.dart';


class PuzzlesBloc implements BlocBase {

  final _puzzlesController = StreamController<List<Puzzle>>.broadcast();
  
  // Input stream. We add our puzzle cards to the stream using this variable.
  StreamSink<List<Puzzle>> get _inPuzzles => _puzzlesController.sink;

  // Output stream. This one will be used within our pages to display the puzzle cards.
  Stream<List<Puzzle>> get puzzles => _puzzlesController.stream;

  final _addPuzzleController = StreamController<Puzzle>.broadcast();
  // Input stream for adding new puzzle cards. We'll call this from our pages.
  StreamSink<Puzzle> get inAddpuzzle => _addPuzzleController.sink;

  PuzzlesBloc() {
    // Fetch all the puzzle cards on initialisation
    getPuzzles();

    // Listens for changes to the addPuzzleController and calls _handleAddPuzzle on change
    _addPuzzleController.stream.listen(_handleAddPuzzle);
  }

  // All stream controllers you create should be closed within this function
  @override
  void dispose() {
    _puzzlesController.close();
    _addPuzzleController.close();
  }

  void getPuzzles() async {
    // Retrieve all the puzzles from the repository
    List<Puzzle> puzzles = await Repository.getPuzzles();

    // Add all of the puzzle cards to the stream so we can grab them later from our pages
    _inPuzzles.add(puzzles);
  }

  void _handleAddPuzzle(Puzzle puzzle) async {
    // Retrieve all the puzzle cards again after one is added.
    // This allows our pages to update properly and display the
    // newly added puzzle card.
    getPuzzles();
  }
}
