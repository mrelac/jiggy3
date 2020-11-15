import 'dart:async';

import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle.dart';

import 'bloc_provider.dart';


class PuzzleCardsBloc implements BlocBase {

  final _puzzleCardsController = StreamController<List<Puzzle>>.broadcast();
  
  // Input stream. We add our puzzle cards to the stream using this variable.
  StreamSink<List<Puzzle>> get _inPuzzles => _puzzleCardsController.sink;

  // Output stream. This one will be used within our pages to display the puzzle cards.
  Stream<List<Puzzle>> get puzzleCards => _puzzleCardsController.stream;

  final _addPuzzleController = StreamController<Puzzle>.broadcast();
  // Input stream for adding new puzzle cards. We'll call this from our pages.
  StreamSink<Puzzle> get inAddpuzzleCard => _addPuzzleController.sink;

  PuzzlesBloc() {
    // Fetch all the puzzle cards on initialisation
    getPuzzles();

    // Listens for changes to the addPuzzleController and calls _handleAddPuzzle on change
    _addPuzzleController.stream.listen(_handleAddPuzzle);
  }

  // All stream controllers you create should be closed within this function
  @override
  void dispose() {
    _puzzleCardsController.close();
    _addPuzzleController.close();
  }

  void getPuzzles() async {
    // Retrieve all the puzzle cards from the repository
    List<Puzzle> puzzleCards = await Repository.repo.getPuzzles();

    // Add all of the puzzle cards to the stream so we can grab them later from our pages
    _inPuzzles.add(puzzleCards);
  }

  void _handleAddPuzzle(Puzzle puzzleCard) async {
    // Retrieve all the puzzle cards again after one is added.
    // This allows our pages to update properly and display the
    // newly added puzzle card.
    getPuzzles();
  }
}
