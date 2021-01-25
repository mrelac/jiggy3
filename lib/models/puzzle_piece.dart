import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class PuzzlePiece {
  int id;
  final int puzzleId;
  final Uint8List imageBytes;
  final double imageWidth;
  final double imageHeight;
  bool locked; // true: piece is in its home location.
  final int homeRow; // This piece's home row.
  final int homeCol; // This piece's home column.
  int lastRow; // This piece's last row. If null, it's never been played.
  int lastCol; // This piece's last column. If null, it's never been played.
  final int maxRow;
  final int maxCol;
  final Image image;

  PuzzlePiece(
      {this.id,
      this.puzzleId,
      this.imageBytes,
      this.imageWidth,
      this.imageHeight,
      this.locked: false,
      this.homeRow,
      this.homeCol,
      this.lastRow,
      this.lastCol,
      this.maxRow,
      this.maxCol})
      : image = Image.memory(imageBytes);

  PuzzlePiece.fromMap(Map json)
      : assert(json['id'] != null),
        assert(json['puzzle_id'] != null),
        assert(json['image_bytes'] != null),
        assert(json['image_width'] != null),
        assert(json['image_height'] != null),
        assert(json['locked'] != null),
        assert(json['home_row'] != null),
        assert(json['home_col'] != null),
        assert(json['max_row'] != null),
        assert(json['max_col'] != null),
        id = json['id'],
        puzzleId = json['puzzle_id'],
        imageBytes = base64Decode(json['image_bytes']),
        imageWidth = json['image_width'],
        imageHeight = json['image_height'],
        locked = json['locked'] == 1 ? true : false,
        homeRow = json['home_row'],
        homeCol = json['home_col'],
        lastRow = json['last_row'],
        lastCol = json['last_col'],
        maxRow = json['max_row'],
        maxCol = json['max_col'],
        image = Image.memory(base64Decode(json['image_bytes']));

  @override
  String toString() {
    return 'PuzzlePiece{id: $id,'
        ' puzzleId: $puzzleId,'
        ' homeRow: $homeRow,'
        ' homeCol: $homeCol,'
        ' lastRow: $lastRow,'
        ' lastCol: $lastCol,'
        ' maxRow: $maxRow,'
        ' maxCol: $maxCol,'
        ' imageWidth: $imageWidth,'
        ' imageHeight: $imageHeight,'
        ' locked: $locked';
  }
}
