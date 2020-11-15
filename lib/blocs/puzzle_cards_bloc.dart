import 'dart:async';

import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle_card.dart';

import 'bloc_provider.dart';


class PuzzleCardsBloc implements BlocBase {

  final _puzzleCardsController = StreamController<List<PuzzleCard>>.broadcast();
  
  // Input stream. We add our puzzle cards to the stream using this variable.
  StreamSink<List<PuzzleCard>> get _inPuzzleCards => _puzzleCardsController.sink;

  // Output stream. This one will be used within our pages to display the puzzle cards.
  Stream<List<PuzzleCard>> get puzzleCards => _puzzleCardsController.stream;

  final _addPuzzleCardController = StreamController<PuzzleCard>.broadcast();
  // Input stream for adding new puzzle cards. We'll call this from our pages.
  StreamSink<PuzzleCard> get inAddpuzzleCard => _addPuzzleCardController.sink;

  PuzzleCardsBloc() {
    // Fetch all the puzzle cards on initialisation
    getPuzzleCards();

    // Listens for changes to the addPuzzleController and calls _handleAddPuzzle on change
    _addPuzzleCardController.stream.listen(_handleAddPuzzleCard);
  }

  // All stream controllers you create should be closed within this function
  @override
  void dispose() {
    _puzzleCardsController.close();
    _addPuzzleCardController.close();
  }

  void getPuzzleCards() async {
    // Retrieve all the puzzle cards from the repository
    List<PuzzleCard> puzzleCards = await Repository.repo.getPuzzleCards();

    // Add all of the puzzle cards to the stream so we can grab them later from our pages
    _inPuzzleCards.add(puzzleCards);
  }

  void _handleAddPuzzleCard(PuzzleCard puzzleCard) async {
    // Retrieve all the puzzle cards again after one is added.
    // This allows our pages to update properly and display the
    // newly added puzzle card.
    getPuzzleCards();
  }




}
