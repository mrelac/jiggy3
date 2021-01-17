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
  bool locked;  // true: piece is in its correct location.
  bool played;  // true: draw on palette; false: put in listview
  int row;
  int col;
  final int maxRow;
  final int maxCol;
  final Image image;
  double _top;
  double _left;

  PuzzlePiece(
      {this.id,
      this.puzzleId,
      this.imageBytes,
      this.imageWidth,
      this.imageHeight,
      this.locked: false,
      this.played: false,
      this.row,
      this.col,
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
        assert(json['played'] != null),
        assert(json['row'] != null),
        assert(json['col'] != null),
        assert(json['max_row'] != null),
        assert(json['max_col'] != null),
        id = json['id'],
        puzzleId = json['puzzle_id'],
        imageBytes = base64Decode(json['image_bytes']),
        imageWidth = json['image_width'],
        imageHeight = json['image_height'],
        locked = json['locked'] == 1 ? true : false,
        played = json['played'] == 1 ? true : false,
        row = json['row'],
        col = json['col'],
        maxRow = json['max_row'],
        maxCol = json['max_col'],
        image = Image.memory(base64Decode(json['image_bytes']));

  // @override
// FIXME Why is there a build widget in a model class?
  Widget build(BuildContext context) {
    final imageWidth = MediaQuery.of(context).size.width;
    final imageHeight = MediaQuery.of(context).size.height *
        MediaQuery.of(context).size.width /
        imageWidth;
    final pieceWidth = imageWidth / maxCol;
    final pieceHeight = imageHeight / maxRow;

    if (_top == null) {
      _top = Random().nextInt((imageHeight - pieceHeight).ceil()).toDouble();
      _top -= row * pieceHeight;
    }
    if (_left == null) {
      _left = Random().nextInt((imageWidth - pieceWidth).ceil()).toDouble();
      _left -= col * pieceWidth;
    }

    return Positioned(
      top: _top,
      left: _left,
      width: imageWidth,
      child: ClipPath(
        child: CustomPaint(
            foregroundPainter: PuzzlePiecePainter(row, col, maxRow, maxCol),
            child: image),
        clipper: PuzzlePieceClipper(row, col, maxRow, maxCol),
      ),
    );
  }
}

// this class is used to clip the image to the puzzle piece path
class PuzzlePieceClipper extends CustomClipper<Path> {
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;

  PuzzlePieceClipper(this.row, this.col, this.maxRow, this.maxCol);

  @override
  Path getClip(Size size) {
    return getPiecePath(size, row, col, maxRow, maxCol);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// this class is used to draw a border around the clipped image
class PuzzlePiecePainter extends CustomPainter {
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;

  PuzzlePiecePainter(this.row, this.col, this.maxRow, this.maxCol);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Color(0x80FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(getPiecePath(size, row, col, maxRow, maxCol), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// this is the path used to clip the image and, then, to draw a border around it; here we actually draw the puzzle piece
Path getPiecePath(Size size, int row, int col, int maxRow, int maxCol) {
  final width = size.width / maxCol;
  final height = size.height / maxRow;
  final offsetX = col * width;
  final offsetY = row * height;
  final bumpSize = height / 4;

  var path = Path();
  path.moveTo(offsetX, offsetY);

  if (row == 0) {
    // top side piece
    path.lineTo(offsetX + width, offsetY);
  } else {
    // top bump
    path.lineTo(offsetX + width / 3, offsetY);
    path.cubicTo(
        offsetX + width / 6,
        offsetY - bumpSize,
        offsetX + width / 6 * 5,
        offsetY - bumpSize,
        offsetX + width / 3 * 2,
        offsetY);
    path.lineTo(offsetX + width, offsetY);
  }

  if (col == maxCol - 1) {
    // right side piece
    path.lineTo(offsetX + width, offsetY + height);
  } else {
    // right bump
    path.lineTo(offsetX + width, offsetY + height / 3);
    path.cubicTo(
        offsetX + width - bumpSize,
        offsetY + height / 6,
        offsetX + width - bumpSize,
        offsetY + height / 6 * 5,
        offsetX + width,
        offsetY + height / 3 * 2);
    path.lineTo(offsetX + width, offsetY + height);
  }

  if (row == maxRow - 1) {
    // bottom side piece
    path.lineTo(offsetX, offsetY + height);
  } else {
    // bottom bump
    path.lineTo(offsetX + width / 3 * 2, offsetY + height);
    path.cubicTo(
        offsetX + width / 6 * 5,
        offsetY + height - bumpSize,
        offsetX + width / 6,
        offsetY + height - bumpSize,
        offsetX + width / 3,
        offsetY + height);
    path.lineTo(offsetX, offsetY + height);
  }

  if (col == 0) {
    // left side piece
    path.close();
  } else {
    // left bump
    path.lineTo(offsetX, offsetY + height / 3 * 2);
    path.cubicTo(
        offsetX - bumpSize,
        offsetY + height / 6 * 5,
        offsetX - bumpSize,
        offsetY + height / 6,
        offsetX,
        offsetY + height / 3);
    path.close();
  }

  return path;
}
