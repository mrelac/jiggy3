import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/data/database.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';

import 'bloc_provider.dart';

class ChooserBloc extends Cubit<List<Album>> implements BlocBase {
  static bool _applicationResetting = false;
  static bool _isInEditMode = false;
  Progress progress;
  List<Album> _albumCache;

  // An entry in the list means object is marked for delete.
  final _albumsMarkedForDelete = Set<int>();
  final _puzzlesMarkedForDelete = Set<int>();

  final _albumNames = Set();
  final _puzzleNames = Set();

  ChooserBloc() : super(<Album>[]) {
    getAlbums();
  }

  final _albumsStream = StreamController<List<Album>>.broadcast();

  Stream<List<Album>> get albumsStream => _albumsStream.stream;

  final _editModeStream = StreamController<bool>.broadcast();

  Stream<bool> get editModeStream => _editModeStream.stream;

  void setEditMode(bool value) {
    _isInEditMode = value;
    _editModeStream.sink.add(value);
  }

  bool get isInEditMode => _isInEditMode;

  void getAlbums() async {
    _albumCache = await Repository.getAlbums();
    _albumNames
      ..clear()
      ..add((_albumCache).map<String>((album) => album.name));

    _puzzleNames
      ..clear()
      ..add((_albumCache
              .firstWhere((album) => album.name == Repository.ALBUM_ALL)
              .puzzles)
          .map<String>((puzzle) => puzzle.name));
    _albumsStream.sink.add(_albumCache);
  }

  bool isApplicationResetting() {
    return _applicationResetting;
  }

  /// Delete albums from database.  Removes bindings first.
  /// Album puzzles are NOT deleted.
  void deleteAlbums(List<Album> albums) async {
    await Repository.deleteAlbums(albums);
    _albumsStream.sink.add(albums);
  }

  /// Delete puzzle images from device storage and delete puzzles and bindings
  /// from database.
  void deletePuzzles(List<Puzzle> puzzles) async {
    await Repository.deletePuzzles(puzzles);
    getAlbums();
  }

  /// Reset the application: drop and create database and image storage file
  /// directories and load seed albums from assets.
  Future<void> applicationReset() async {
    _applicationResetting = true;
    progress = Progress('Resetting application environment', 0.0);
    List<Album> albums = await Repository.applicationResetEnvironment();
    int puzzleCount = 0;
    albums.forEach((a) => puzzleCount += (a?.puzzles?.length) ?? 0);
    int currentPuzzleIndex = 0;
    for (Album album in albums) {
      await Repository.createAlbum(album);
      for (Puzzle puzzle in album.puzzles) {
        progress = Progress(
            'Creating puzzle "${puzzle.name}" in album "${album.name}"',
            currentPuzzleIndex / puzzleCount);
        await Repository.createPuzzle(puzzle);
        await Repository.bindAlbumAndPuzzle(album.id, puzzle.id);
        _albumsStream.sink.add([album]);
        currentPuzzleIndex++;
      }
    }

    _applicationResetting = false;
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
  /// Unbind the puzzle and the album.
  void removePuzzleFromAlbum(
      {@required Puzzle puzzle, @required Album album}) async {}

  // STATE MANAGEMENT: EDITING METHODS

  void clearItemsMarkedForDelete() {
    _albumsMarkedForDelete.clear();
    _puzzlesMarkedForDelete.clear();
  }

  bool shouldDeleteAlbum(int id) {
    return _albumsMarkedForDelete.contains(id);
  }

  void toggleDeleteAlbum(Album album, bool shouldDelete) {
    shouldDelete
        ? _albumsMarkedForDelete.add(album.id)
        : _albumsMarkedForDelete.remove(album.id);

    print('toggleDeleteAlbum "${album.name}": new Value: $shouldDelete');
    _albumsStream.sink.add(_albumCache);
  }

  bool shouldDeletePuzzle(int id) {
    return _puzzlesMarkedForDelete.contains(id);
  }

  void toggleDeletePuzzle(Puzzle puzzle, bool shouldDelete) {
    shouldDelete
        ? _puzzlesMarkedForDelete.add(puzzle.id)
        : _puzzlesMarkedForDelete.remove(puzzle.id);

    print('toggleDeletePuzzle "${puzzle.name}": new value: $shouldDelete');
    _albumsStream.sink.add(_albumCache);
  }

  Future<void> dumpTables() async {
    await DBProvider.db.dumpTable('album');
    await DBProvider.db.dumpTable('puzzle');
    await DBProvider.db.dumpTable('album_puzzle');
    await DBProvider.db.dumpTable('puzzle_piece');
  }

  // All stream controllers you create should be closed within this function
  @override
  void dispose() {
    _albumsStream.close();
    _editModeStream.close();
  }
}

class Progress {
  final String progress;
  final double percent;

  const Progress(this.progress, this.percent);

  @override
  String toString() {
    return 'Progress{progress: $progress, percent: $percent}';
  }
}
