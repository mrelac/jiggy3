import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/data/database.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';

class ChooserBloc extends Cubit<List<Album>> {
  static bool _applicationResetting = false;
  static bool _isInEditMode = false;
  Progress progress;
  List<Album> _albumCache;

  // An entry in the list means object is marked for delete/being edited
  final _albumsMarkedForDelete = Set<int>();
  final _puzzlesMarkedForDelete = Set<int>();

  final _albumNames = Set<String>();

  List<String> getAlbumNames() => _albumNames.map((name) => name).toList();

  final _puzzleNames = Set<String>();

  List<String> getPuzzleNames() => _puzzleNames.map((name) => name).toList();

  ChooserBloc() : super(<Album>[]) {
    getAlbums();
  }

  final _albumsStream = StreamController<List<Album>>.broadcast();

  Stream<List<Album>> get albumsStream => _albumsStream.stream;

  final _editModeStream = StreamController<bool>.broadcast();

  Stream<bool> get editModeStream => _editModeStream.stream;

  final _editingNameStream = StreamController<Key>.broadcast();

  Stream<Key> get editingNameStream => _editingNameStream.stream;

  void setEditMode(bool value) {
    _isInEditMode = value;
    _albumsMarkedForDelete.clear();
    _puzzlesMarkedForDelete.clear();
    _editModeStream.sink.add(value);
    _editingNameStream.sink.add(null);
  }

  bool get isInEditMode => _isInEditMode;

  Future<void> getAlbums() async {
    _albumCache = await Repository.getAlbums();
    _albumNames
      ..clear()
      ..addAll((_albumCache).map<String>((album) => album.name));

    _puzzleNames
      ..clear()
      ..addAll((_albumCache
              .firstWhere((album) => album.name == Repository.ALBUM_ALL)
              .puzzles)
          .map<String>((puzzle) => puzzle.name));
    _albumsStream.sink.add(_albumCache);
  }

  bool isApplicationResetting() {
    return _applicationResetting;
  }

  Future<void> deleteSelectedItems() async {
    int itemCount =
        _puzzlesMarkedForDelete.length + _albumsMarkedForDelete.length;
    int currentIndex = 0;
    for (int albumId in _albumsMarkedForDelete) {
      currentIndex++;
      Album album = await Repository.getAlbumById(albumId);
      progress =
          Progress('Deleting album "${album.name}"', currentIndex / itemCount);
      await Repository.deleteAlbum(albumId);
    }

    for (int puzzleId in _puzzlesMarkedForDelete) {
      currentIndex++;
      Puzzle puzzle = await Repository.getPuzzleById(puzzleId);
      progress = Progress(
          'Deleting puzzle "${puzzle.name}"', currentIndex / itemCount);
      await Repository.deletePuzzle(puzzleId);
    }
  }

  Future<void> updatePuzzleName(String oldName, String newName) async {
    await Repository.updatePuzzleName(oldName, newName);
    getAlbums();
  }

  Future<void> updateAlbumName(String oldName, String newName) async {
    await Repository.updateAlbumName(oldName, newName);
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

  /// Create new, empty Album from name, add to database, and refresh album list.
  void createAlbum(String name) async {
    Album newAlbum = Album(name: name);
    await Repository.createAlbum(newAlbum);
    _albumCache.add(newAlbum);
    _albumsStream.sink.add([newAlbum]);
  }

  /// Create new puzzle from puzzle.name and puzzle.imageLocation, copy image
  /// to device storage, fill out remainder of Puzzle fields, and add puzzle to
  /// database.
  void createPuzzle(String name, String imageLocation) async {
    Puzzle newPuzzle = await Repository.createPuzzle(
        Puzzle(name: name, imageLocation: imageLocation));
    Album all = await Repository.getAlbumAll();
    all.puzzles.insert(0, newPuzzle);
    _albumsStream.sink.add([all]);
  }

// TODO - addPuzzleToAlbum()
  /// Bind the puzzle to the album.
  void addPuzzleToAlbum(
      {@required Puzzle puzzle, @required Album album}) async {}

// TODO - removePuzzleFromAlbum()
  /// Unbind the puzzle and the album.
  void removePuzzleFromAlbum(
      {@required Puzzle puzzle, @required Album album}) async {}

  // STATE MANAGEMENT: EDITING METHODS

  int countItemsMarkedForDelete() {
    return _albumsMarkedForDelete.length + _puzzlesMarkedForDelete.length;
  }

  bool isAlbumMarkedForDelete(int id) {
    return _albumsMarkedForDelete.contains(id);
  }

  void toggleDeleteAlbum(Album album, bool shouldDelete) {
    shouldDelete
        ? _albumsMarkedForDelete.add(album.id)
        : _albumsMarkedForDelete.remove(album.id);

    print('toggleDeleteAlbum "${album.name}": new Value: $shouldDelete');
    _albumsStream.sink.add(_albumCache);
  }

  bool isPuzzleMarkedForDelete(int id) {
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

  void dispose() {
    _albumsStream.close();
    _editModeStream.close();
    _editingNameStream.close();
    print('ChooserBloc: DISPOSING!!!');
  }

  /// Adds the key to the editingNameStream sink, to which all interested
  /// parties (e.g. Albums, ChooserCards, etc) have subscribed. A null key
  /// indicates the caller is unsubscribing and nobody is editing.
  /// If a non-null request is made while another editing request is in
  /// progress, an exception is thrown.
  Key _editingNameKey;

  Key get editingNameKey => _editingNameKey;

  void editingNameRequest(Key key) async {
    if ((key != null) && (_editingNameKey != null)) {
      throw Exception(
          'ChooserBloc.editingNameRequest(): request made while request is in progress.');
    }
    await getAlbums();
    _editingNameKey = key;
    _editingNameStream.sink.add(_editingNameKey);
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
