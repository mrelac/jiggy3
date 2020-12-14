import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jiggy3/data/jiggy_filesystem.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/services/chooser_service.dart';
import 'package:jiggy3/services/image_service.dart';
import 'package:jiggy3/utilities/image_utilities.dart';

import 'database.dart';

const ASSETS_PATH = 'assets/puzzles.json';
const THUMB_WIDTH = 240.0;

class Repository {
  static const ALBUM_ALL = 'All';
  static const ALBUM_SAVED = 'Saved';
  // ALBUMS

  /// Returns all albums and their puzzles. The returned list of albums will
  /// never be empty, as the non-editable albums 'All' and 'Saved' are always
  /// returned, even if there are no puzzles.
  static Future<List<Album>> getAlbums() async {
    return <Album>[]
      ..add(await _getAlbumSaved())
      ..add(await _getAlbumAll())
      ..addAll(await DBProvider.db.getAlbums());
  }

  static Future<void> createAlbum(Album album) async {
    if (album.isSelectable) {
      await DBProvider.db.insertAlbum(album);
    }
  }

  /// Delete albums from database.  Removes bindings first.
  /// Album puzzles are NOT deleted.
  static Future<void> deleteAlbums(List<Album> albums) async {
    await DBProvider.db.deleteAlbums(albums);
  }

  // PUZZLES

  // Get all puzzles
  static Future<List<Puzzle>> getPuzzles() async {
    return (await DBProvider.db.getPuzzles());
  }

  static Future<void> createPuzzle(Puzzle puzzle) async {
      Uint8List sourceBytes =
      await ChooserService.readImageBytesFromLocation(puzzle.imageLocation);
      String targetLocation =
      await JiggyFilesystem.createTargetImagePath(puzzle.name);
      Size size = await ImageUtils.getImageSize(Image.memory(sourceBytes));
      await JiggyFilesystem.imageBytesSave(sourceBytes, File(targetLocation));
      puzzle
        ..thumb = ImageService.resizeBytes(sourceBytes, THUMB_WIDTH)
        ..imageLocation = targetLocation
        ..imageWidth = size.width
        ..imageHeight = size.height;
    await DBProvider.db.insertPuzzle(puzzle);
  }

  /// Delete puzzle images from device storage and delete puzzles and bindings
  /// from database.
  static Future<void> deletePuzzles(List<Puzzle> puzzles) async {
    puzzles.forEach((puzzle) async =>
        await JiggyFilesystem.imageFileDelete(File(puzzle.imageLocation)));
    await DBProvider.db.deletePuzzles(puzzles);
  }

  /// Reset the application: drop and create database and image storage file
  /// directories and return a list of asset albums with puzzles.
  static Future<List<Album>> applicationResetEnvironment() async {
    await DBProvider.db.deleteJiggyDatabase();
    await JiggyFilesystem.appImagesDirectoryDelete();
    await JiggyFilesystem.appImagesDirectoryCreate();
    String jsonStr = await rootBundle.loadString(ASSETS_PATH);
    List<dynamic> jsonData = jsonDecode(jsonStr);
    final albums = <Album>[];
    jsonData
        .forEach((jsonAlbum) => albums.add(Album.fromMap(jsonAlbum['album'])));
    return albums;
  }

  static Future<void> bindAlbumAndPuzzle(int albumId, int puzzleId) async {
    await DBProvider.db.bindAlbumAndPuzzle(albumId, puzzleId);
  }

  // PRIVATE METHODS

  /// Returns a single album named 'all' containing all unique puzzles
  static Future<Album> _getAlbumAll() async {
    final List<Puzzle> puzzles = await DBProvider.db.getPuzzles();
    return Album(isSelectable: false, name: ALBUM_ALL, puzzles: puzzles);
  }

  // Returns a single album named 'Saved' containing all puzzles in progress
  static Future<Album> _getAlbumSaved() async {
    // throw Exception('Not implemented yet');
    // FIXME Add logic to return Saved puzzles
    // FIXME Add logic to return Saved puzzles
    // FIXME Add logic to return Saved puzzles
    // FIXME Add logic to return Saved puzzles
    // FIXME Add logic to return Saved puzzles
    return Album(isSelectable: false, name: ALBUM_SAVED, puzzles: []);
  }
}
