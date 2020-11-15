BEGIN;
INSERT INTO album
  (id, name, is_selectable)
VALUES
  (1, 'Saved',     0),
  (2, 'All',       0),
  (3, 'Mountains', 1),
  (4, 'Places',    1),
  (5, 'Flowers',   1);

COMMIT;

BEGIN;
INSERT INTO puzzle
  (id, name, play_state)
VALUES
  ( 1, 'Mountains',        1),
  ( 2, 'Hallstatt',        2),
  ( 3, 'Hallstätter See',  1),
  ( 4, 'Tower Bridge',     1),
  ( 5, 'Birmingham',       2),
  ( 6, 'Birmingham BCN',   1),
  ( 7, 'Birmingham Boats', 2),
  ( 8, 'Budapest',         1),
  ( 9, 'Flowers',          1),
  (10, 'Dow Farm',         1);

COMMIT;

BEGIN;
INSERT INTO album_puzzle
VALUES
  ( 1, 3,  1),
  ( 2, 4,  2),
  ( 3, 4,  3),
  ( 4, 4,  4),
  ( 5, 4,  5),
  ( 6, 4,  6),
  ( 7, 4,  7),
  ( 8, 4,  8),
  ( 9, 5,  9),
  (10, 5, 10);

COMMIT;

-- ( 1, 'Mountains',        1, readfile('/Users/mrelac/workspace/jiggy/assets/img/Snowy.jpg')),
-- ( 2, 'Hallstatt',        2, readfile('/Users/mrelac/workspace/jiggy/assets/img/Hallstatt.jpg')),
-- ( 3, 'Hallstätter See',  1, readfile('/Users/mrelac/workspace/jiggy/assets/img/Hallstätter_See.jpg')),
-- ( 4, 'Tower Bridge',     1, readfile('/Users/mrelac/workspace/jiggy/assets/img/TowerBridge.jpg')),
-- ( 5, 'Birmingham',       2, readfile('/Users/mrelac/workspace/jiggy/assets/img/Birmingham.jpg')),
-- ( 6, 'Birmingham BCN',   1, readfile('/Users/mrelac/workspace/jiggy/assets/img/BirminghamBCN.jpg')),
-- ( 7, 'Birmingham Boats', 2, readfile('/Users/mrelac/workspace/jiggy/assets/img/BirminghamBoats.jpg')),
-- ( 8, 'Budapest',         1, readfile('/Users/mrelac/workspace/jiggy/assets/img/Budapest.jpg')),
-- ( 9, 'Flowers',          1, readfile('/Users/mrelac/workspace/jiggy/assets/img/Flowers.jpg')),
-- (10, 'Dow Farm',         1, readfile('/Users/mrelac/workspace/jiggy/assets/img/dow-farm-1.jpg'));
