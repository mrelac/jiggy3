import 'dart:convert';

import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  static final _dbName = 'jiggy.db';
  static final _dbVersion = 1;
  static Database _database;

  // Make class a singleton
  DBProvider._private();

  static final DBProvider db = DBProvider._private();

  Future<Database> get database async {
    if (_database == null) {
      _database = await openDatabase(
        join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) => _createTables(db, version),
        version: _dbVersion,
      );
    }

    return _database;
  }

  // DB ACCESS

  Future<void> deleteJiggyDatabase() async {
    // To delete the database using deleteDatabase, do NOT include the path.
    await deleteDatabase(_dbName);
    _database = null;
    print('Deleted database $_dbName');
  }

  Future<void> dumpTable(String tableName) async {
    final db = await database;
    String query = 'SELECT * FROM $tableName';
    var jsonResults = await db.rawQuery(query);
    print("");
    print('Dumping table "$tableName"');
    for (var json in jsonResults) {
      print(json);
    }
  }

  // ALBUMS

  /// Returns all albums and their puzzles, or an empty list if there are no
  /// albums.
  Future<List<Album>> getAlbums() async {
    final db = await database;
    List<Album> albums = (await db.rawQuery('SELECT * FROM album'))
        .map((json) => Album.fromMap(json))
        .toList();
    if (albums.isNotEmpty) {
      for (Album album in albums) {
        album.puzzles.addAll(await getPuzzlesByAlbum(album.id));
      }
    }
    return albums;
  }

  Future<void> insertAlbum(Album album) async {
    final db = await database;
    const insert = 'INSERT INTO album (name) VALUES (?)';
    album.id = await db.rawInsert(insert, [album.name]);
  }

  /// Deletes albums using albumId. Removes bindings first.
  Future<void> deleteAlbums(List<Album> albums) async {
    print('Deleting ${albums.length} album(s)).');
    _deleteBindingsByAlbum(albums);
    final batch = (await database).batch();
    albums.forEach((album) =>
        batch.rawDelete("DELETE FROM album WHERE id = ?", [album.id]));
    await batch.commit(noResult: true);
  }

  // PUZZLES

  /// Returns all puzzles, or an empty list if there are no puzzles
  Future<List<Puzzle>> getPuzzles() async {
    final db = await database;
    return ((await db.rawQuery('SELECT * FROM puzzle'))
        .map<Puzzle>((json) => Puzzle.fromMap(json))
        .toList());
  }

  Future<void> insertPuzzle(Puzzle puzzle) async {
    final db = await database;
    const String insert = '''
INSERT INTO puzzle
  (name, thumb, image_location, image_width, image_height,
   image_colour_r, image_colour_g, image_colour_b,
   image_opacity, max_pieces)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''';
    print('Inserting puzzle ${puzzle.name}');
    puzzle.id = await db.rawInsert(insert, [
      puzzle.name,
      base64Encode(puzzle.thumb),
      puzzle.imageLocation,
      puzzle.imageWidth,
      puzzle.imageHeight,
      puzzle.imageColour.red,
      puzzle.imageColour.green,
      puzzle.imageColour.blue,
      puzzle.imageOpacity,
      puzzle.maxPieces
    ]);
  }

  /// Deletes puzzles using puzzle id. Removes bindings first.
  Future<void> deletePuzzles(List<Puzzle> puzzles) async {
    final db = await database;
    Batch batch = db.batch();
    puzzles.forEach((puzzle) async {
      _deleteBindingsByPuzzle(puzzles);
      print('Deleting puzzle ${puzzle.name}');
      batch.rawDelete('DELETE FROM puzzle WHERE id = ?', [puzzle.id]);
    });
    await batch.commit(noResult: true);
  }

  /// Return a list of jsonPuzzle entries matching albumId. An empty puzzle list
  /// is returned if there are no bound puzzles.
  Future<List<Puzzle>> getPuzzlesByAlbum(int albumId) async {
    const String query = '''
SELECT p.* FROM puzzle p
 JOIN album_puzzle ap ON ap.puzzle_id = p.id
 JOIN album a ON a.id = ap.album_id
 WHERE a.id = ?;
    ''';
    final db = await database;
    return ((await db.rawQuery(query, [albumId]))
        .map<Puzzle>((json) => Puzzle.fromMap(json))
        .toList());
  }

  /// Bind puzzle to album. Undefined behaviour if binding already exists.
  Future<void> bindAlbumAndPuzzle(int albumId, int puzzleId) async {
    final db = await database;
    const String insert =
        'INSERT INTO album_puzzle(album_id, puzzle_id) VALUES(?, ?)';
    await db.rawInsert(insert, [albumId, puzzleId]);
      print('Bound puzzleId $puzzleId to albumId $albumId');
  }

  // PRIVATE METHODS

  /// Deletes album_puzzle bindings for specified albums.
  Future<void> _deleteBindingsByAlbum(List<Album> albums) async {
    final Batch batch = (await database).batch();
    albums.forEach((album) {
      print('Unbinding all puzzles from album ${album.name}');
      batch
          .rawDelete("DELETE FROM album_puzzle WHERE album_id = ?", [album.id]);
    });
    await batch.commit(noResult: true);
  }

  /// Deletes album_puzzle bindings for specified puzzles.
  Future<void> _deleteBindingsByPuzzle(List<Puzzle> puzzles) async {
    final Batch batch = (await database).batch();
    puzzles.forEach((puzzle) {
      print('Unbinding puzzle ${puzzle.name}');
      batch.rawDelete(
          "DELETE FROM album_puzzle WHERE puzzle_id = ?", [puzzle.id]);
    });
    await batch.commit(noResult: true);
  }

  void _createTables(Database db, int version) {
    print('Creating jiggy database');

    print('Creating album table');
    db.execute('''
CREATE TABLE album(
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  name             TEXT NOT NULL UNIQUE
);
  ''');

    print('Creating puzzle table');
    db.execute('''
CREATE TABLE puzzle(
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  name             TEXT    NOT NULL UNIQUE,
  thumb            BLOB,
  image_location   TEXT    NOT NULL, 
  image_width      REAL,
  image_height     REAL,
  image_colour_r   INTEGER,
  image_colour_g   INTEGER,
  image_colour_b   INTEGER,
  image_opacity    REAL,
  max_pieces       INTEGER
);
  ''');

    print('Creating puzzle_piece table');
    db.execute('''
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
    db.execute('''
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
