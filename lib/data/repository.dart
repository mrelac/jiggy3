import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jiggy3/data/jiggy_filesystem.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/services/image_service.dart';
import 'package:jiggy3/utilities/image_utilities.dart';

import 'database.dart';

const ASSETS_PATH = 'assets/puzzles.json';
const THUMB_WIDTH = 240.0;

class Repository {
  static const ALBUM_ALL = 'All';
  static const ALBUM_SAVED = 'Saved';

  // ALBUMS

  static Future<Album> getAlbumById(int albumId) async {
    return await DBProvider.db.getAlbumById(albumId);
  }

  static Future<Album> getAlbumByPuzzleId(int puzzleId) async {
    return await DBProvider.db.getAlbumByPuzzleId(puzzleId);
  }

  /// Returns all albums and their puzzles. The returned list of albums will
  /// never be empty, as the non-editable albums 'All' and 'Saved' are always
  /// returned, even if there are no puzzles.
  static Future<List<Album>> getAlbums() async {
    return <Album>[]
      ..add(await getAlbumSaved())
      ..add(await getAlbumAll())
      ..addAll(await DBProvider.db.getAlbums());
  }

  /// Insert album into the database.
  static Future<void> createAlbum(Album album) async {
    if (album.isSelectable) {
      await DBProvider.db.insertAlbum(album);
    }
  }

  /// Delete album from database.  Removes bindings first.
  /// Album puzzles are NOT deleted.
  static Future<void> deleteAlbum(int albumId) async {
    await DBProvider.db.deleteAlbum(albumId);
  }

  static Future<void> updateAlbumName(String oldName, String newName) async {
    await DBProvider.db.updateAlbumName(oldName, newName);
  }

  // PUZZLES

  // Get all puzzles
  static Future<List<Puzzle>> getPuzzles() async {
    return (await DBProvider.db.getPuzzles());
  }

  /// Create new puzzle from puzzle.name and puzzle.imageLocation, copy image
  /// to device storage, fill out remainder of Puzzle fields, and return the
  /// puzzle. NOTE: Does NOT add the puzzle to the database.
  static Future<Puzzle> createPuzzle(String name, String imageLocation) async {
    Uint8List sourceBytes =
        await ImageService.readImageBytesFromLocation(imageLocation);
    String targetLocation = await JiggyFilesystem.createTargetImagePath(name);
    Size size = await ImageUtils.getImageSize(Image.memory(sourceBytes));
    await JiggyFilesystem.bytesImageSave(sourceBytes, File(targetLocation));
    final puzzle = Puzzle(
        name: name,
        imageLocation: targetLocation,
        thumb: ImageService.resizeBytes(sourceBytes, THUMB_WIDTH),
        imageHeight: size.height,
        imageWidth: size.width);
    return puzzle;
  }

  /// Create new puzzle from puzzle.name and puzzle.imageLocation, copy image
  /// to device storage, fill out remainder of Puzzle fields, and add puzzle to
  /// database.
  static Future<Puzzle> createAndInsertPuzzle(
      String name, String imageLocation) async {
    Puzzle puzzle = await createPuzzle(name, imageLocation);
    return await DBProvider.db.insertPuzzle(puzzle);
  }

  /// Delete puzzle image from device storage and delete puzzle and binding,
  /// if any, from database.
  /// from database.
  static Future<void> deletePuzzle(int puzzleId) async {
    Puzzle puzzle = await DBProvider.db.getPuzzleById(puzzleId);
    if (puzzle != null) {
      await deletePuzzleImage(puzzle.imageLocation);
    }
    await DBProvider.db.deletePuzzle(puzzleId);
  }

  static Future<Puzzle> getPuzzleById(int puzzleId) async {
    return await DBProvider.db.getPuzzleById(puzzleId);
  }

  static Future<Puzzle> getPuzzleByName(String name) async {
    return await DBProvider.db.getPuzzleByName(name);
  }

  static Future<List<Puzzle>> getPuzzlesByAlbumId(int albumId) async {
    return await DBProvider.db.getPuzzlesByAlbumId(albumId);
  }

  static Image getPuzzleImage(String location, double height, double width) {
    return Image.file(File(location), width: width, height: height);
  }

  static Future<void> deletePuzzleImage(String location) async {
    await JiggyFilesystem.fileImageDelete(File(location));
  }

  static Future<void> updatePuzzle(int id,
      {String name,
      Uint8List thumb,
      String imageLocation,
      double imageWidth,
      double imageHeight,
      Color imageColour,
      double imageOpacity,
      int maxPieces}) async {
    await DBProvider.db.updatePuzzle(id,
        name: name,
        thumb: thumb,
        imageLocation: imageLocation,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        imageColour: imageColour,
        imageOpacity: imageOpacity,
        maxPieces: maxPieces);
  }

  /// Reset the application: drop and create database and image storage file
  /// directories and return a list of asset albums with puzzles.
  static Future<List<Album>> applicationResetEnvironment() async {
    await DBProvider.db.deleteJiggyDatabase();
    await JiggyFilesystem.directoryImagesDelete();
    await JiggyFilesystem.directoryPicturesDelete();
    await JiggyFilesystem.directoryImagesCreate();
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

  /// Returns a single album named 'all' containing all unique puzzles
  static Future<Album> getAlbumAll() async {
    final List<Puzzle> puzzles = await DBProvider.db.getPuzzles();
    return Album(isSelectable: false, name: ALBUM_ALL, puzzles: puzzles);
  }

  // Returns a single album named 'Saved' containing all puzzles in progress
  static Future<Album> getAlbumSaved() async {
    // throw Exception('Not implemented yet');
    // TODO - getAlbumSaved()
    return Album(isSelectable: false, name: ALBUM_SAVED, puzzles: []);
  }
}
