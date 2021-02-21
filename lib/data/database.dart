import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';
import 'package:jiggy3/models/rc.dart';
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
      if (tableName == 'puzzle') {
        print(Puzzle.fromMap(json));
      } else if (tableName == 'puzzle_piece') {
        // Don't print anything
      } else {
        print(json);
      }
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
    // This throws an exception when a request to rebuild the database is
    // specified. It comes about as a result of ChooserBloc seeding the list of
    // albums and is not fatal if the query doesn't complete. So it is wrapped
    // in a try/catch and exceptions are ignored.
    var puzzles = <Puzzle>[];
    try {
      puzzles = (await db.rawQuery('SELECT * FROM puzzle'))
          .map<Puzzle>((json) => Puzzle.fromMap(json))
          .toList();
    } catch (e) {}
    return puzzles;
  }

  Future<Puzzle> insertPuzzle(Puzzle puzzle) async {
    final db = await database;
    const String insert = '''
INSERT INTO puzzle
  (name, thumb, image_location,
   image_colour_r, image_colour_g, image_colour_b,
   image_opacity, max_rows, max_cols, num_locked)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''';
    print('Inserting puzzle ${puzzle.name}');
    puzzle.id = await db.rawInsert(insert, [
      puzzle.name,
      base64Encode(puzzle.thumb),
      puzzle.imageLocation,
      puzzle.imageColour.red,
      puzzle.imageColour.green,
      puzzle.imageColour.blue,
      puzzle.imageOpacity,
      puzzle?.maxRc?.row ?? 0,
      puzzle?.maxRc?.col ?? 0,
      puzzle.numLocked
    ]);
    return puzzle;
  }

  Future<List<PuzzlePiece>> getPuzzlePieces(int puzzleId) async {
    final db = await database;
    const String select = 'SELECT * FROM puzzle_piece WHERE puzzle_id = ?';
    return ((await db.rawQuery(select, [puzzleId]))
        .map<PuzzlePiece>((json) => PuzzlePiece.fromMap(json))
        .toList());
  }

  Future<void> insertPuzzlePieces(List<PuzzlePiece> pieces) async {
    final db = _database.batch();
    const String insert = '''
INSERT INTO puzzle_piece
  (puzzle_id, image_bytes, image_width, image_height, locked,
   home_row, home_col, last_row, last_col)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''';
    pieces.forEach((piece) async => db.rawInsert(insert, [
          piece.puzzleId,
          base64Encode(piece.imageBytes),
          piece.imageWidth,
          piece.imageHeight,
          piece.locked,
          piece.home.row,
          piece.home.col,
          piece?.last?.row,
          piece?.last?.col
        ]));
    await db.commit(noResult: true);
  }

  Future<PuzzlePiece> insertPuzzlePiece(PuzzlePiece piece) async {
    final db = await database;
    const String insert = '''
INSERT INTO puzzle_piece
  (puzzle_id, image_bytes, image_width, image_height, locked,
   home_row, home_col, last_row, last_col
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''';
    piece.id = await db.rawInsert(insert, [
      piece.puzzleId,
      base64Encode(piece.imageBytes),
      piece.imageWidth,
      piece.imageHeight,
      piece.locked,
      piece.home.row,
      piece.home.col,
      piece?.last?.row,
      piece?.last?.col
    ]);
    return piece;
  }

  Future<void> updatePuzzlePieceLast(int puzzlePieceId, RC last) async {
    final db = await database;
    final String update =
        'UPDATE puzzle_piece SET last_row = ?, last_col = ? WHERE id = ?';
    await db.rawUpdate(update, [last.row, last.col, puzzlePieceId]);
  }

  Future<void> updatePuzzlePiece(int puzzlePieceId,
      {bool locked, RC home}) async {
    final db = await database;

    final fields = <String>[];
    final parms = <dynamic>[];

    if (locked != null) {
      fields.add('locked = ?');
      parms.add(locked ? 1 : 0);
    }
    if (home != null) {
      fields..add('home_row = ?')..add('home_col = ?');
      parms..add(home.row)..add(home.col);
    }
    parms.add(puzzlePieceId);

    final String update =
        'UPDATE puzzle_piece SET ' + fields.join(",") + ' WHERE id = ?';
    print('Database.updatePuzzlePiece QUERY: $update($parms)}');
    await db.rawUpdate(update, parms);
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

  Future<void> deletePuzzlePieces(int puzzleId) async {
    final db = await database;
    const delete = "DELETE from puzzle_piece where puzzle_id = ?";
    int count = await db.rawDelete(delete, [puzzleId]);
    if (count > 0) {
      print('Deleted $count puzzle pieces for puzzle_id $puzzleId');
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

  /// Return puzzle from name. Returns puzzle instance if found; null otherwise
  Future<Puzzle> getPuzzleByName(String name) async {
    final db = await database;
    const query = 'SELECT * FROM puzzle WHERE name = ?';
    List<Puzzle> puzzleList = (await db.rawQuery(query, [name]))
        .map<Puzzle>((json) => Puzzle.fromMap(json))
        .toList();
    return puzzleList.isEmpty ? null : puzzleList.first;
  }

  // Updates only the non-null parameter values.
  Future<void> updatePuzzle(int id,
      {String name,
      Uint8List thumb,
      String imageLocation,
      Color imageColour,
      double imageOpacity,
      RC maxRc,
      int numLocked,
      int previousMaxPieces}) async {
    final db = await database;
    final fields = <String>[];
    final parms = <dynamic>[];

    if (name != null) {
      fields.add('name = ?');
      parms.add(name);
    }
    if (thumb != null) {
      fields.add('thumb = ?');
      parms.add(base64Encode(thumb));
    }
    if (imageLocation != null) {
      fields.add('image_location = ?');
      parms.add(imageLocation);
    }
    if (imageColour != null) {
      fields
        ..add('image_colour_r = ?')
        ..add('image_colour_g = ?')
        ..add('image_colour_b = ?');
      parms
        ..add(imageColour.red)
        ..add(imageColour.green)
        ..add(imageColour.blue);
    }
    if (imageOpacity != null) {
      fields.add('image_opacity = ?');
      parms.add(imageOpacity);
    }
    if (maxRc != null) {
      fields..add('max_rows = ?')..add('max_cols = ?');
      parms..add(maxRc.row)..add(maxRc.col);
    }
    if (previousMaxPieces != null) {
      fields.add('previous_max_pieces = ?');
      parms.add(previousMaxPieces);
    }
    if (numLocked != null) {
      fields.add('num_locked = ?');
      parms.add(numLocked);
    }
    parms.add(id);

    final String update =
        'UPDATE puzzle SET ' + fields.join(",") + ' WHERE id = ?';

    int count = await db.rawUpdate(update, parms);
    if (count > 0) {
      print('Updated puzzle. Query: $update. parms = $parms');
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
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
    );
    ''');

    print('Creating puzzle table');
    db.execute('''
    CREATE TABLE puzzle(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    thumb BLOB,
    image_location TEXT NOT NULL,
    image_colour_r INTEGER,
    image_colour_g INTEGER,
    image_colour_b INTEGER,
    image_opacity REAL,
    max_rows INTEGER NOT NULL,
    max_cols INTEGER NOT NULL,
    num_locked INTEGER NOT NULL,
    previous_max_pieces INTEGER
    );
    ''');

    print('Creating puzzle_piece table');
    db.execute('''
    CREATE TABLE puzzle_piece(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    puzzle_id INTEGER NOT NULL,
    image_bytes BLOB NOT NULL,
    image_width REAL NOT NULL,
    image_height REAL NOT NULL,
    locked INTEGER NOT NULL,
    home_row INTEGER NOT NULL,
    home_col INTEGER NOT NULL,
    last_row INTEGER DEFAULT NULL,
    last_col INTEGER DEFAULT NULL,
    FOREIGN KEY (puzzle_id) REFERENCES puzzle (id)
    ON DELETE NO ACTION ON UPDATE NO ACTION
    );
    ''');

    print('Creating album_puzzle table');
    db.execute('''
    CREATE TABLE album_puzzle(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    album_id INTEGER NOT NULL,
    puzzle_id INTEGER NOT NULL,
    FOREIGN KEY (album_id) REFERENCES album (id)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (puzzle_id) REFERENCES puzzle (id)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
    UNIQUE(album_id, puzzle_id)
    );
    ''');
  }
}
