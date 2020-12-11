import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/models/puzzle.dart';

/// Move these to chooser_service.
@deprecated
class CommonUtils {
  // static Album getAlbumByName({String albumName, List<Album> albums}) {
  //   return albums.firstWhere(
  //     (Album album) {
  //       return (album.label.toLowerCase() == albumName.toLowerCase());
  //     },
  //     orElse: () => null,
  //   );
  // }

  static Puzzle findPuzzleInPuzzles({Puzzle puzzle, List<Puzzle> puzzles}) {
    return puzzles.firstWhere( (Puzzle p) { return (p.name.toLowerCase() == puzzle.name.toLowerCase()); }, orElse: () => null);
  }

  static Puzzle findPuzzleInAlbum({Puzzle puzzle, Album album}) {
    return findPuzzleInPuzzles(puzzle: puzzle, puzzles: album.puzzles);
  }

  // FIXME This should go in AlbumsBloc where the full list is available.
  /// Returns the first [Album] containing the puzzle, else the none() album
  // static Album findAlbumContainingPuzzle(Puzzle puzzle) {
  //   Puzzle p;
  //   for (Album album in globals.albums) {
  //     Puzzle p = findPuzzleInAlbum(puzzle: puzzle, album: album);
  //     if (p != null)
  //       return album;
  //   }
  //
  //   return none();
  // }

  // FIXME This should go in PuzzlesBloc where the full list is available.
  // static String getDefaultPuzzleName([String prefix]) {
  //   prefix = prefix ?? 'New Puzzle';
  //   if (globals.puzzles.isEmpty) {
  //     return prefix;
  //   }
  //
  //   Puzzle a = Puzzle(name: prefix);
  //   int i = 1;
  //   while (globals.puzzles.contains(a)) {
  //     a = Puzzle(name: '$prefix ' + i.toString());
  //     i++;
  //   }
  //
  //   return a.name;
  // }

  // FIXME This should go in AlbumsBloc where the full list is available.
  // static String getDefaultAlbumName() {
  //   if (globals.albums.isEmpty) {
  //     return 'New Album 1';
  //   }
  //
  //   Album a;
  //   for (int i = 1; ; i++) {
  //     a = Album(name: 'New Album ' + i.toString());
  //     if ( ! globals.albums.contains(a))
  //       break;
  //   }
  //
  //   return a.name;
  // }

  // FIXME This should go in AlbumsBloc where the full list is available.
  // static List<Puzzle> getSavedPuzzles() {
  //   var saved = <Puzzle>[];
  //   if ((globals.puzzles != null) && (globals.puzzles.isNotEmpty)) {
  //     globals.puzzles.forEach((puzzle) {
  //       if (puzzle.playState == PlayState.inProgress) saved.add(puzzle);
  //     });
  //     saved = List.from(saved);
  //   }
  //
  //   return saved;
  // }

  // static Album none() {
  //   return Album(name: '<none>', isSelectable: true, isTicked:  false,
  //                puzzles: []);
  // }
}