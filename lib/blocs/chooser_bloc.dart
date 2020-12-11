import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';

import 'bloc_provider.dart';

class ChooserBloc extends Cubit<List<Album>> implements BlocBase {
  // An entry in the list means object is marked for delete.
  final _albumsMarkedForDelete = Set();
  final _puzzlesMarkedForDelete = Set();

  final _albumNames = Set();
  final _puzzleNames = Set();

  ChooserBloc() : super(<Album>[]) {
    getAlbums();
  }

  final _albumsStream = StreamController<List<Album>>.broadcast();

  Stream<List<Album>> get albumsStream => _albumsStream.stream;

  void getAlbums() async {
    List<Album> albums = await Repository.getAlbums();
    _albumNames
      ..clear()
      ..add((await Repository.getAlbums()).map<String>((album) => album.name));

    _puzzleNames
      ..clear()
      ..add(
          (await Repository.getPuzzles()).map<String>((puzzle) => puzzle.name));
    _albumsStream.sink.add(albums);
  }

  /// Create albums. Non-selectable albums are filtered out. The only fields in
  /// each Puzzle that are used are name and imageLocation, starting
  /// with e.g.:
  ///  - ASSET IMAGE PATH: an imageLocation file path starting with 'assets'
  ///  - FILE IMAGE PATH: an imageLocation file path starting with '/'
  ///  - NETWORK IMAGE PATH: an imageLocation network path starting with 'http'
  void createAlbums(List<Album> albums) async {
    await Repository.createAlbums(albums);
    _albumsStream.sink.add(albums);
  }

  /// Delete albums from database.  Removes bindings first.
  /// Album puzzles are NOT deleted.
  void deleteAlbums(List<Album> albums) async {
    await Repository.deleteAlbums(albums);
    _albumsStream.sink.add(albums);
  }

  /// Create puzzles. The only fields in each Puzzle that are used are
  /// name and imageLocation, starting with e.g.:
  ///  - ASSET IMAGE PATH: an imageLocation file path starting with 'assets'
  ///  - FILE IMAGE PATH: an imageLocation file path starting with '/'
  ///  - NETWORK IMAGE PATH: an imageLocation network path starting with 'http'
  void createPuzzles(List<Puzzle> puzzles) async {
    await Repository.createPuzzles(puzzles);
    getAlbums();
  }

  /// Delete puzzle images from device storage and delete puzzles and bindings
  /// from database.
  void deletePuzzles(List<Puzzle> puzzles) async {
    await Repository.deletePuzzles(puzzles);
    getAlbums();
  }

  /// Reset the application: drop and create database and image storage file
  /// directories and load seed albums from assets.
  void applicationReset() async {
    await Repository.applicationReset();
    getAlbums();
  }

// TODO - Implement
  /// Create new, empty Album from name, add to database, and refresh album list.
  void createAlbum(String name) async {
    _albumsStream.sink.add([Album(name: name)]);
  }

// TODO - Implement
  /// Remove puzzle bindings, delete the album from the database, and
  /// refresh the album list.
  void deleteAlbum(int albumId) async {
    // await Repository.deleteAlbum(albumId);
  }

// TODO - Implement
  void editAlbumName(Album album) {
    print('AlbumsBloc: editing album name for album ${album.name}');
  }

// TODO - Implement
  /// Create new puzzle from name and imageLocation, copy image to device
  /// storage, add puzzle to database, and refresh the album list.
  void createPuzzle(String name, String imageLocation) async {}

// TODO - Implement
  /// Remove puzzle binding, delete the puzzle image from device storage,
  /// delete the puzzle from the database, and refresh the album list.
  void deletePuzzle(int puzzleId) async {}

// TODO - Implement
  void editPuzzleName(Puzzle puzzle) {
    print('AlbumsBloc: editing puzzle name for puzzle ${puzzle.name}');
  }

// TODO - Implement
  /// Bind the puzzle to the album.
  void addPuzzleToAlbum(
      {@required Puzzle puzzle, @required Album album}) async {}

// TODO - Implement
  /// Undbind the puzzle and the album.
  void removePuzzleFromAlbum(
      {@required Puzzle puzzle, @required Album album}) async {}

  // STATE MANAGEMENT: EDITING METHODS

  void clearAlbumsMarkedForDelete() {
    _albumsMarkedForDelete.clear();
    getAlbums();
  }

  bool shouldDeleteAlbum(int id) {
    return _albumsMarkedForDelete.contains(id);
  }

  void toggleDeleteAlbum(int id, bool shouldDelete) {
    shouldDelete
        ? _albumsMarkedForDelete.add(id)
        : _albumsMarkedForDelete.remove(id);

    print('shouldDeleteAlbum id $id: new Value: $shouldDelete');
    getAlbums();
  }

  void clearPuzzlesMarkedForDelete() {
    _puzzlesMarkedForDelete.clear();
    getAlbums();
  }

  bool shouldDeletePuzzle(int id) {
    return _puzzlesMarkedForDelete.contains(id);
  }

  void toggleDeletePuzzle(int id, bool shouldDelete) {
    shouldDelete
        ? _puzzlesMarkedForDelete.add(id)
        : _puzzlesMarkedForDelete.remove(id);

    print('shouldDeletePuzzle id $id: new value: $shouldDelete');
    getAlbums();
  }

  // All stream controllers you create should be closed within this function
  @override
  void dispose() {
    _albumsStream.close();
  }
}
