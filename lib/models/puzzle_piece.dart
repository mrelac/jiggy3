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
  bool locked;    // true: piece is in its home location.
  double homeDy;  // The top coordinate of this piece's home position
  double homeDx;  // The left coordinate of this piece's home position
  double lastTop;  // The top coordinate of this piece's last position, or null if it's never been played
  double lastLeft;  // The left coordinate of this piece's last position, or null if it's never been played.
  final Image image;

  PuzzlePiece(
      {this.id,
      this.puzzleId,
      this.imageBytes,
      this.imageWidth,
      this.imageHeight,
      this.locked: false,
      this.homeDy,
      this.homeDx,
      this.lastTop,
      this.lastLeft,
      })
      : image = Image.memory(imageBytes);

  PuzzlePiece.fromMap(Map json)
      : assert(json['id'] != null),
        assert(json['puzzle_id'] != null),
        assert(json['image_bytes'] != null),
        assert(json['image_width'] != null),
        assert(json['image_height'] != null),
        assert(json['locked'] != null),
        assert(json['home_dy'] != null),
        assert(json['home_dx'] != null),
        id = json['id'],
        puzzleId = json['puzzle_id'],
        imageBytes = base64Decode(json['image_bytes']),
        imageWidth = json['image_width'],
        imageHeight = json['image_height'],
        locked = json['locked'] == 1 ? true : false,
        homeDy = json['home_dy'],
        homeDx = json['home_dx'],
        lastTop = json['last_dy'],
        lastLeft = json['last_dx'],
        image = Image.memory(base64Decode(json['image_bytes']));

  @override
  String toString() {
    return 'PuzzlePiece{id: $id,'
        ' puzzleId: $puzzleId,'
        ' homeRow: $homeDy,'
        ' homeCol: $homeDx,'
        ' lastRow: $lastTop,'
        ' lastCol: $lastLeft,'
        ' imageWidth: $imageWidth,'
        ' imageHeight: $imageHeight,'
        ' locked: $locked';
  }
}
