import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class PuzzlePiece {
  int id;
  final int puzzleId;
  final Uint8List imageBytes;
  final double imageWidth;
  final double imageHeight;
  bool locked;   // true: piece is in its home location.
  double homeDx; // The left coordinate of this piece's home position
  double homeDy; // The top coordinate of this piece's home position
  double lastDx; // The left coordinate of this piece's last position, or null if in listview.
  double lastDy; // The top coordinate of this piece's last position, or null if in listview.
  final Image image;

  PuzzlePiece({
    this.id,
    this.puzzleId,
    this.imageBytes,
    this.imageWidth,
    this.imageHeight,
    this.locked: false,
    this.homeDx,
    this.homeDy,
    this.lastDx,
    this.lastDy,
  }) : image = Image.memory(imageBytes);

  PuzzlePiece.fromMap(Map json)
      : assert(json['id'] != null),
        assert(json['puzzle_id'] != null),
        assert(json['image_bytes'] != null),
        assert(json['image_width'] != null),
        assert(json['image_height'] != null),
        assert(json['locked'] != null),
        assert(json['home_dx'] != null),
        assert(json['home_dy'] != null),
        id = json['id'],
        puzzleId = json['puzzle_id'],
        imageBytes = base64Decode(json['image_bytes']),
        imageWidth = json['image_width'],
        imageHeight = json['image_height'],
        locked = json['locked'] == 1 ? true : false,
        homeDx = json['home_dx'],
        homeDy = json['home_dy'],
        lastDx = json['last_dx'],
        lastDy = json['last_dy'],
        image = Image.memory(base64Decode(json['image_bytes']));

  @override
  String toString() {
    return 'PuzzlePiece{id: $id,'
        ' puzzleId: $puzzleId,'
        ' homeDx: $homeDx,'
        ' homeDy: $homeDy,'
        ' lastDx: $lastDx,'
        ' lastDy: $lastDy,'
        ' imageWidth: $imageWidth,'
        ' imageHeight: $imageHeight,'
        ' locked: $locked';
  }
}
