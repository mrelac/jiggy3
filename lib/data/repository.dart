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

  /// Create albums. Non-selectable albums are filtered out. The only fields in
  /// each Puzzle that are used are name and imageLocation, starting
  /// with e.g.:
  ///  - ASSET IMAGE PATH: an imageLocation file path starting with 'assets'
  ///  - FILE IMAGE PATH: an imageLocation file path starting with '/'
  ///  - NETWORK IMAGE PATH: an imageLocation network path starting with 'http'
  ///
  /// Steps:
  ///  - For each album:
  ///    - Create puzzles
  ///    - Add puzzles to database
  ///  - Insert album and its puzzle bindings into the database
  static Future<void> createAlbums(List<Album> albums) async {
    for (Album album in albums) {
      if (album.isSelectable) {
        await createPuzzles(album.puzzles);
      }
    }
    await DBProvider.db.insertAlbums(albums);
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

  /// Create puzzles. The only fields in each Puzzle that are used are
  /// name and imageLocation, starting with e.g.:
  ///  - ASSET IMAGE PATH: an imageLocation file path starting with 'assets'
  ///  - FILE IMAGE PATH: an imageLocation file path starting with '/'
  ///  - NETWORK IMAGE PATH: an imageLocation network path starting with 'http'
  ///
  /// Steps:
  ///  - For each puzzle:
  ///    - Create source image file path from imageLocation
  ///    - Create target image file path from puzzle name
  ///    - Copy image file from source to target
  ///    - Update puzzle fields (thumb, imageLocation, imageWidth, imageHeight)
  ///  - Add puzzles to database.
  static Future<void> createPuzzles(List<Puzzle> puzzles) async {
    for (Puzzle puzzle in puzzles) {
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
    };
    await DBProvider.db.insertPuzzles(puzzles);
  }

  /// Delete puzzle images from device storage and delete puzzles and bindings
  /// from database.
  static Future<void> deletePuzzles(List<Puzzle> puzzles) async {
    puzzles.forEach((puzzle) async =>
        await JiggyFilesystem.imageFileDelete(File(puzzle.imageLocation)));
    await DBProvider.db.deletePuzzles(puzzles);
  }

  /// Reset the application: drop and create database and image storage file
  /// directories and load seed albums from assets.
  static Future<void> applicationReset() async {
    await DBProvider.db.deleteJiggyDatabase();
    await JiggyFilesystem.appImagesDirectoryDelete();
    await JiggyFilesystem.appImagesDirectoryCreate();

    String jsonStr = await rootBundle.loadString(ASSETS_PATH);
    List<dynamic> jsonData = jsonDecode(jsonStr);
    final albums = <Album>[];
    jsonData
        .forEach((jsonAlbum) => albums.add(Album.fromMap(jsonAlbum['album'])));
    await createAlbums(albums);
  }

  // PRIVATE METHODS

  /// Returns a single album named 'all' containing all unique puzzles
  static Future<Album> _getAlbumAll() async {
    final List<Puzzle> puzzles = await DBProvider.db.getPuzzles();
    return Album(isSelectable: false, name: 'All', puzzles: puzzles);
  }

  // Returns a single album named 'Saved' containing all puzzles in progress
  static Future<Album> _getAlbumSaved() async {
    // throw Exception('Not implemented yet');
    // FIXME Add logic to return Saved puzzles
    // FIXME Add logic to return Saved puzzles
    // FIXME Add logic to return Saved puzzles
    // FIXME Add logic to return Saved puzzles
    // FIXME Add logic to return Saved puzzles
    return Album(isSelectable: false, name: 'Saved', puzzles: []);
  }
}
