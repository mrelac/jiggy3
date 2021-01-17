import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jiggy3/data/jiggy_filesystem.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';
import 'package:jiggy3/services/image_service.dart';

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

  static Future<Puzzle> createPuzzle(String name, String imageLocation) async {
    String targetLocation = await JiggyFilesystem.createTargetImagePath(name);
    Uint8List sourceBytes =
        await ImageService.readImageBytesFromLocation(imageLocation);
    Size sourceSize = await ImageService.getImageSizeFromBytes(sourceBytes);
    Uint8List fitBytes = await ImageService.fitImageBytesToDevice(sourceBytes);
    Size fitSize = await ImageService.getImageSizeFromBytes(fitBytes);
    await JiggyFilesystem.bytesImageSave(fitBytes, File(targetLocation));
    print('fit image $sourceSize to $fitSize');
    final puzzle = Puzzle(
        name: name,
        imageLocation: targetLocation,
        thumb: ImageService.resizeBytes(sourceBytes, THUMB_WIDTH));
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

  static Future<Image> getPuzzleImage(String location) async {
    Image image = Image.file(File(location));
    Size size = await ImageService.getImageSize(image);
    return Image.file(File(location), width: size.width, height: size.height);
  }

  static Future<List<Puzzle>> getPuzzlesByAlbumId(int albumId) async {
    return await DBProvider.db.getPuzzlesByAlbumId(albumId);
  }

  static Future<List<PuzzlePiece>> getPuzzlePieces(int puzzleId) async {
    return (await DBProvider.db.getPuzzlePieces(puzzleId));
  }

  static Future<PuzzlePiece> insertPuzzlePiece(PuzzlePiece piece) async {
    return await DBProvider.db.insertPuzzlePiece(piece);
  }

  static Future<void> updatePuzzlePieceLocked(
      int puzzlePieceId, bool isLocked) async {
    return await DBProvider.db
        .updatePuzzlePiece(puzzlePieceId, locked: isLocked);
  }

  static Future<void> updatePuzzlePiecePlayed(
      int puzzlePieceId, bool isPlayed) async {
    return await DBProvider.db
        .updatePuzzlePiece(puzzlePieceId, played: isPlayed);
  }

  static Future<void> updatePuzzlePiecePosition(
      int puzzlePieceId, int row, int col) async {
    return await DBProvider.db
        .updatePuzzlePiece(puzzlePieceId, row: row, col: col);
  }

  static Future<void> deletePuzzleImage(String location) async {
    await JiggyFilesystem.fileImageDelete(File(location));
  }

  static Future<void> updatePuzzle(int id,
      {String name,
      Uint8List thumb,
      String imageLocation,
      Color imageColour,
      double imageOpacity,
      int maxPieces}) async {
    await DBProvider.db.updatePuzzle(id,
        name: name,
        thumb: thumb,
        imageLocation: imageLocation,
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
    final List<Puzzle> puzzles = (await DBProvider.db.getPuzzles())
        .where((p) => p.maxPieces > -1)
        .toList();
    return Album(isSelectable: false, name: ALBUM_SAVED, puzzles: puzzles);
  }
}
