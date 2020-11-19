import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


// TODO: Port contents of Persist to here.

// All rows are returned as a list of maps, where each map is
// a key-value list of columns.


class DBProvider {
  static final _dbName = 'jiggy.db';
  static final _dbVersion = 1;
  static Database _database;

  // Make class a singleton
  DBProvider._private();

  static final DBProvider db = DBProvider._private();

  Future<Database> get database async {
    if (_database == null) {
      _database = await _initialise();
    }

    return _database;
  }


  // db access methods here

  Future<void> close() async {
    final db = await database;
    await db.close();
  }


  Future<void> deleteJiggyDatabase() async {
    // To delete the database using deleteDatabase, do NOT include the path.
    await deleteDatabase(_dbName);
    print('Deleted database $_dbName');
  }

  Future<void> dumpTable(String tableName) async {
    final db = await database;
    String query = 'SELECT * FROM $tableName';
    var jsonResults = await db.rawQuery(query);

    print("");
    print('Dumping table "$tableName"');
    for (var json in jsonResults) {
      print (json);
    }
  }


  Future<List<Map<String, dynamic>>> getAlbums() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM album');
}

  Future<Puzzle> createPuzzle(Puzzle puzzle) async {
    final db = await database;
    var parms;

      String insert =
      '''
INSERT INTO puzzle
  (label, thumb, imageLocation, image_width, image_height,
   image_colour_r, image_colour_g, image_colour_b,
   image_opacity, max_pieces)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
''';
      parms = [puzzle.label, base64Encode(puzzle.thumb), puzzle.imageLocation,
        puzzle.imageWidth, puzzle.imageHeight,
        puzzle.imageColour.red, puzzle.imageColour.green, puzzle.imageColour.blue,
        puzzle.imageOpacity, puzzle.maxPieces];
      puzzle.id = await db.rawInsert(insert, parms);
      print('INSERTed puzzle ${puzzle.label} (id: ${puzzle.id})');
    return puzzle;
  }

  Future<List<Map<String, dynamic>>> getPuzzlesByAlbum(int albumId) async {
    const String query = '''
SELECT p.* FROM puzzle p
 JOIN album_puzzle ap ON ap.puzzle_id = p.id
 JOIN album a ON a.id = ap.album_id
 WHERE a.label = ?;
    ''';

    final db = await database;
    return await db.rawQuery(query, [albumId]);
  }

  Future<List<Map<String, dynamic>>> getPuzzles() async {
    final db = await database;
    String query = 'SELECT * FROM puzzle;';
    return await db.rawQuery(query);
  }

  Future<Database> _initialise() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _dbName);
    return
        await openDatabase(path, version: _dbVersion, onCreate: _createTables);
//      if ( ! await _tableExists('puzzle')) {
//        await _createTables();
//      }
  }


  // PRIVATE METHODS

  Future<void> _createTables(Database db, int version) async {
    final db = await database;
    // Create category table
    print('Creating jiggy database');
    print('Creating album table');
    await db.execute('''
CREATE TABLE album(
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  label            TEXT NOT NULL UNIQUE,
  is_selectable    INTEGER DEFAULT 1
);
  ''');

    print('Creating puzzle table');
    await db.execute('''
CREATE TABLE puzzle(
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  label            TEXT    NOT NULL UNIQUE,
  thumb            BLOB,
  image_location   TEXT    NOT NULL, 
  image_width      REAL,
  image_height     REAL,
  image_colour_r   INTEGER,
  image_colour_g   INTEGER,
  image_colour_b   INTEGER,
  image_opacity    REAL
  max_pieces       INTEGER,
);
  ''');

    print('Creating puzzle_piece table');
    await db.execute('''
CREATE TABLE puzzle_piece(
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  puzzle_id        INTEGER NOT NULL,
  image_bytes      BLOB    NOT NULL,
  image_width      REAL    NOT NULL,
  image_weight     REAL    NOT NULL,
  locked           INTEGER NOT NULL,
  row              INTEGER NOT NULL,
  col              INTEGER NOT NULL,
  max_row          INTEGER NOT NULL,
  max_col          INTEGER NOT NULL,

  FOREIGN KEY (puzzle_id) REFERENCES puzzle (id)
    ON DELETE NO ACTION ON UPDATE NO ACTION
);
  ''');

    print('Creating album_puzzle table');
    await db.execute('''
CREATE TABLE album_puzzle(
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  album_id         INTEGER NOT NULL,
  puzzle_id        INTEGER NOT NULL,

  FOREIGN KEY (album_id) REFERENCES album (id)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (puzzle_id) REFERENCES puzzle (id)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  UNIQUE(album_id, puzzle_id)
);
  ''');
  }

}
