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
        album.puzzles.addAll(await getPuzzlesByAlbumId(album.id));
      }
    }
    return albums;
  }

  Future<void> insertAlbum(Album album) async {
    final db = await database;
    const insert = 'INSERT INTO album (name) VALUES (?)';
    album.id = await db.rawInsert(insert, [album.name]);
    print('Inserted album ${album.name} into database');
  }

  /// Deletes albums using albumId. Removes bindings first.
  Future<void> deleteAlbum(int albumId) async {
    _deleteBindingsByAlbumId(albumId);
    final db = await database;
    Album album = await getAlbumById(albumId);
    int count = await db.rawDelete("DELETE FROM album WHERE id = ?", [albumId]);
    if (count > 0) {
      print('Deleted album ${album.name} from database');
    }
  }

  Future<void> updateAlbumName(String oldName, String newName) async {
    final db = await database;
    const update = 'UPDATE album SET name = ? WHERE name = ?';
    int count = await db.rawUpdate(update, [newName, oldName]);
    if (count > 0) {
      print('Updated album "$oldName" to "$newName"');
    }
  }

  /// Return album from albumId. Returns album instance if found; null otherwise
  Future<Album> getAlbumById(int albumId) async {
    final db = await database;
    const query = 'SELECT * FROM album WHERE id = ?';
    List<Album> albumList = (await db.rawQuery(query, [albumId]))
        .map<Album>((json) => Album.fromMap(json))
        .toList();
    return albumList.isEmpty ? null : albumList.first;
  }

  Future<Album> getAlbumByPuzzleId(int puzzleId) async {
    const query = '''
SELECT a.* FROM album a
 JOIN album_puzzle ap ON ap.album_id = a.id
 JOIN puzzle p ON p.id = ap.puzzle_id
 WHERE p.id = ?;
    ''';
    final db = await database;
    List<Album> results = (await db.rawQuery(query, [puzzleId]))
        .map<Album>((json) => Album.fromMap(json))
        .toList();
    return results.isNotEmpty ? results.first : null;
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

  /// Deletes puzzle using puzzle id. Removes binding, if any, first.
  Future<void> deletePuzzle(int puzzleId) async {
    final db = await database;
    Puzzle puzzle = await getPuzzleById(puzzleId);
    const delete = 'DELETE FROM puzzle WHERE id = ?';
    _deleteBindingByPuzzleId(puzzleId);
    int count = await db.rawDelete(delete, [puzzleId]);
    if (count > 0) {
      print('Deleted puzzle ${puzzle.name} from database');
    }
  }

  /// Return puzzle from puzzleId. Returns puzzle instance if found; null otherwise
  Future<Puzzle> getPuzzleById(int puzzleId) async {
    final db = await database;
    const query = 'SELECT * FROM puzzle WHERE id = ?';
    List<Puzzle> puzzleList = (await db.rawQuery(query, [puzzleId]))
        .map<Puzzle>((json) => Puzzle.fromMap(json))
        .toList();
    return puzzleList.isEmpty ? null : puzzleList.first;
  }

  Future<void> updatePuzzleName(String oldName, String newName) async {
    final db = await database;
    const update = 'UPDATE puzzle SET name = ? WHERE name = ?';
    int count = await db.rawUpdate(update, [newName, oldName]);
    if (count > 0) {
      print('Updated puzzle "$oldName" to "$newName"');
    }
  }

  /// Return a list of jsonPuzzle entries matching albumId. An empty puzzle list
  /// is returned if there are no bound puzzles.
  Future<List<Puzzle>> getPuzzlesByAlbumId(int albumId) async {
    const query = '''
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
    Puzzle puzzle = await getPuzzleById(puzzleId);
    Album album = await getAlbumById(albumId);
    final db = await database;
    const insert = 'INSERT INTO album_puzzle(album_id, puzzle_id) VALUES(?, ?)';
    await db.rawInsert(insert, [albumId, puzzleId]);
    print('Bound puzzle ${puzzle.name} to album ${album.name}');
  }

// PRIVATE METHODS

  /// Deletes album_puzzle bindings for specified album id.
  Future<void> _deleteBindingsByAlbumId(int albumId) async {
    final db = await database;
    Album album = await getAlbumById(albumId);
    const delete = 'DELETE FROM album_puzzle WHERE album_id = ?';
    int count = await db.rawDelete(delete, [albumId]);
    if (count > 0) {
      print('Unbound all puzzles for album ${album.name}');
    }
  }

  /// Deletes album_puzzle bindings for specified puzzle id, if any exist.
  Future<void> _deleteBindingByPuzzleId(int puzzleId) async {
    final db = await database;
    final Album album = await getAlbumByPuzzleId(puzzleId);
    if (album != null) {
      Puzzle puzzle = await getPuzzleById(puzzleId);
      const delete = 'DELETE FROM album_puzzle WHERE puzzle_id = ?';
      int count = await db.rawDelete(delete, [puzzleId]);
      if (count > 0) {
        print('Unbound puzzle ${puzzle.name} from album ${album.name}');
      }
    }
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
