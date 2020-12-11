DROP TABLE IF EXISTS album;
CREATE TABLE IF NOT EXISTS album(
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  name             TEXT NOT NULL UNIQUE
);


DROP TABLE IF EXISTS puzzle;
CREATE TABLE IF NOT EXISTS puzzle(
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  name             TEXT    NOT NULL UNIQUE,
  location         TEXT    NOT NULL,
  thumb_blob       BLOB,
  image_width      REAL,
  image_height     REAL,
  max_pieces       INTEGER,
  image_colour_r   INTEGER,
  image_colour_g   INTEGER,
  image_colour_b   INTEGER,
  image_opacity    REAL
);

DROP TABLE IF EXISTS puzzle_piece;
CREATE TABLE IF NOT EXISTS puzzle_piece(
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


DROP TABLE IF EXISTS album_puzzle;
CREATE TABLE IF NOT EXISTS album_puzzle(
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  album_id         INTEGER NOT NULL,
  puzzle_id        INTEGER NOT NULL,

  FOREIGN KEY (album_id) REFERENCES album (id)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (puzzle_id) REFERENCES puzzle (id)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  UNIQUE(album_id, puzzle_id)
);
