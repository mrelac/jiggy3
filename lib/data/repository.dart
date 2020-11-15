import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:sqflite/sqflite.dart';

import 'database.dart';

class Repository {
  static final Repository _repo = new Repository._private();

//  var puzzles = <Puzzle>[];
  var puzzleDeleteIsTicked = <int, bool>{};

  static Database _db;

  static Repository get repo {
    if (_db == null) {}
    return _repo;
  }

  Repository._private();

  Future<void> _initialise() async {
    _db = await DBProvider.db.database;
  }

  Future<Puzzle> createPuzzle(Puzzle puzzle) async {
    return await DBProvider.db.createPuzzle(puzzle);
  }

  Future<List<Puzzle>> getPuzzlesByAlbum(Album album) async {
    List<Map<String, dynamic>> jsonRows =
        await DBProvider.db.getPuzzlesByAlbum(album.id);
    var puzzles = <Puzzle>[];
    for (var jsonRow in jsonRows) {
      puzzles.add(Puzzle.fromMap(jsonRow));
    }
    return puzzles;
  }

  Future<List<Album>> getAlbums() async {
    List<Map<String, dynamic>> jsonRows = await DBProvider.db.getAlbums();
    var albums = <Album>[];
    for (var jsonRow in jsonRows) {
      albums.add(Album.fromMap(jsonRow));
    }
    return albums;
  }

  Future<List<Puzzle>> _getPuzzles() async {
    final List<Map<String, dynamic>> jsonRows =
        await DBProvider.db.getPuzzles();
    return _jsonToPuzzles(jsonRows);
  }

  Future<List<Puzzle>> _getPuzzlesByAlbumId(int albumId) async {
    final List<Map<String, dynamic>> jsonRows =
        await DBProvider.db.getPuzzlesByAlbum(albumId);
    return _jsonToPuzzles(jsonRows);
  }

  List<Puzzle> _jsonToPuzzles(List<Map<String, dynamic>> jsonRows) {
    var puzzles = <Puzzle>[];
    if (jsonRows.isNotEmpty) {
      for (var jsonRow in jsonRows) {
        Puzzle p = Puzzle.fromMap(jsonRow);
        puzzles.add(p);
      }
    }
    return puzzles;
  }

  void puzzleDeleteIsTickedReset() {
    puzzleDeleteIsTicked.clear();
  }

  /// Returns all Puzzles for album, if not null; else, all cards
  Future<List<Puzzle>> getPuzzles({int albumId}) async {
    final List<Puzzle> puzzles = (albumId == null
        ? await _getPuzzles()
        : await _getPuzzlesByAlbumId(albumId));

    final cards = <Puzzle>[];
    for (Puzzle puzzle in puzzles) {
      bool shouldDelete = puzzleDeleteIsTicked[puzzle.id] ?? false;
      cards.add(Puzzle(id: puzzle.id, label: puzzle.label, thumb: puzzle.thumb));
    }
    return cards;
  }

//  PlayState get playState {
//    if (maxPieces == -1) {
//      return PlayState.neverPlayed;
//    } else if (piecesLocked.length == maxPieces) {
//      return PlayState.completed;
//    } else {
//      return PlayState.inProgress;
//    }
//  }

// Repository getters and setters here. These are async methods returning
// futures, but the data source (e.g. database, internet, file system) are
// masked by these public methods.
}
