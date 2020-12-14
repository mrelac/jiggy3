import 'package:jiggy3/models/puzzle.dart';

// Latest thoughts (30-Nov-2020):
// Models like Album and Puzzle shouldn't have any knowledge of edit/add/delete
// events. Keep them pure. Let the View/UI code handle these things.
// MORE: Albums are associated with PuzzleCards, not Puzzles. A Puzzle is just a Puzzle.
// ALTERNATIVE: Make Album a ChooserAlbum with those event properties.

/// Keeps track of an album
class Album {
  int id;
  String name;
  List<Puzzle> puzzles;
  bool isSelectable; // true if album can be modified/deleted

  Album({
    this.id,
    this.name,
    this.puzzles,
    this.isSelectable: true,
  });

  Album.fromMap(Map jsonMap)
      : assert(jsonMap['name'] != null),
        this.id = jsonMap['id'],
        this.name = jsonMap['name'],
        this.puzzles = jsonMap['puzzles'] == null
            ? <Puzzle>[]
            : jsonMap['puzzles'].map<Puzzle>((s) => Puzzle.fromMap(s)).toList(),
        this.isSelectable = true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          runtimeType == other.runtimeType &&
          name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'Album{id: $id, name: $name, isSelectable: $isSelectable';
  }
}
