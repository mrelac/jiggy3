import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jiggy3/models/rc.dart';

class PuzzlePiece {
  int id;
  final int puzzleId;
  final Uint8List imageBytes;
  final double imageWidth;
  final double imageHeight;
  bool isLocked; // true: piece is in its home location.
  RC home = RC(); // This piece's 0-relative home row and column values
  RC last = RC(); // This piece's e 0-relative last row and column values, or null if in listview

  // FIXME get rid of image if not needed
  // final Image image;

  double get homeDy => home?.row == null ? null : home.row * imageHeight;

  double get homeDx => home?.col == null ? null : home.col * imageWidth;

  double get lastDy => last?.row == null ? null : last.row * imageHeight;

  double get lastDx => last?.col == null ? null : last.col * imageWidth;

  // FIXME get rid of image if not needed
  PuzzlePiece(
      {this.id,
      this.puzzleId,
      this.imageBytes,
      this.imageWidth,
      this.imageHeight,
      this.isLocked: false,
      this.home,
      this.last})
      // : image = Image.memory(imageBytes)
  ;

  PuzzlePiece.fromMap(Map json)
      : assert(json['id'] != null),
        assert(json['puzzle_id'] != null),
        // assert(json['image_bytes'] != null),
        assert(json['image_width'] != null),
        assert(json['image_height'] != null),
        assert(json['locked'] != null),
        assert(json['home_row'] != null),
        assert(json['home_col'] != null),
        id = json['id'],
        puzzleId = json['puzzle_id'],
        // imageBytes = base64Decode(json['image_bytes']),
        imageBytes = null,
        imageWidth = json['image_width'],
        imageHeight = json['image_height'],
        isLocked = json['locked'] == 1 ? true : false,
        home = RC(row: json['home_row'], col: json['home_col']),
        last = json['last_row'] == null
            ? RC()
            : RC(row: json['last_row'], col: json['last_col'])
  // ,
        // image = Image.memory(base64Decode(json['image_bytes']))
  ;

  @override
  String toString() {
    return 'PuzzlePiece{id: $id,'
        ' puzzleId: $puzzleId,'
        ' home: $home,'
        ' last: $last,'
        ' imageWidth: $imageWidth,'
        ' imageHeight: $imageHeight,'
        ' locked: $isLocked';
  }
}
