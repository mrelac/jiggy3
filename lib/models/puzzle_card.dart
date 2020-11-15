import 'dart:typed_data';
import 'dart:ui';

class PuzzleCard {
  final int id; // This should match the puzzle primary key
  final Uint8List thumb;
  final String label;
  final bool isEditing;
  final bool shouldDelete;
  final bool showInSaved;

  const PuzzleCard(this.id, this.thumb, this.label,
      {this.isEditing: false, this.shouldDelete: false, this.showInSaved: false});
}
