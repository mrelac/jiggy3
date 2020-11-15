

import 'package:jiggy3/models/puzzle_card.dart';

/// Keeps track of an album
class Album {
  final int id;
  final String label;
  final List<PuzzleCard> puzzleCards;
  final bool isSelectable;      // true if album can be modified/deleted; false otherwise
  final bool isEditing;         // true if editing controls are showing
  final bool shouldDelete;      // true if checkbox is ticked; false if it is not

  const Album({
    this.id,
    this.label,
    this.puzzleCards,
    this.isSelectable: true,
    this.isEditing: false,
    this.shouldDelete: false
  });

  Album.fromMap(Map json)
      : assert(json['id'] != null),
        assert(json['label'] != null),
        assert(json['puzzle_cards'] != null),
        assert(json['is_selectable'] != null),
        this.id = json['id'],
        this.label = json['name'],
        this.puzzleCards = json['puzzle_cards'],
        this.isSelectable = json['is_selectable'] > 0 ? true : false,
        this.isEditing = false,
        this.shouldDelete = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Album &&
              runtimeType == other.runtimeType &&
              label.toLowerCase() == other.label.toLowerCase();

  @override
  int get hashCode => label.hashCode;

  @override
  String toString() {
    return 'Album{id: $id, name: $label, isSelectable: $isSelectable, isEditing: $isEditing, isTicked: $shouldDelete}';
  }
}