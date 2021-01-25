import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jiggy3/models/puzzle_piece.dart';

class Piece extends StatefulWidget {
  final PuzzlePiece puzzlePiece;

  Piece(this.puzzlePiece);

  @override
  _PieceState createState() => _PieceState();
}

/// If the piece has never been played, its lastRow and lastCol will be null
/// and we should return a widget suitable for insertion into the listview;
/// otherwise, the piece has been played and we return a Positioned widget
/// suitable for drawing the widget on the palette in its last known row and
/// column.
class _PieceState extends State<Piece> {
  @override
  Widget build(BuildContext context) {
    return widget.puzzlePiece.lastRow != null
        ? buildPositionedTarget()
        : buildListviewTarget();
  }

  // Return a widget suitable for Positioned placement on the palette.
  Widget buildPositionedTarget() {
    double _top;
    double _left;
    int lastRow = widget.puzzlePiece.lastRow;
    int lastCol = widget.puzzlePiece.lastCol;
    int homeRow = widget.puzzlePiece.homeRow;
    int homeCol = widget.puzzlePiece.homeCol;
    int maxRow = widget.puzzlePiece.maxRow;
    int maxCol = widget.puzzlePiece.maxCol;
    Image image = widget.puzzlePiece.image;

    final imageWidth = MediaQuery.of(context).size.width;
    final imageHeight = MediaQuery.of(context).size.height *
        MediaQuery.of(context).size.width /
        imageWidth;
    final pieceWidth = imageWidth / maxCol;
    final pieceHeight = imageHeight / maxRow;

    if (_top == null) {
      _top = Random().nextInt((imageHeight - pieceHeight).ceil()).toDouble();
      _top -= lastRow * pieceHeight;
    }
    if (_left == null) {
      _left = Random().nextInt((imageWidth - pieceWidth).ceil()).toDouble();
      _left -= lastCol * pieceWidth;
    }

    return Positioned(
      top: _top,
      left: _left,
      width: imageWidth,
      child: ClipPath(
        child: CustomPaint(
            foregroundPainter: PiecePainter(lastRow, lastCol, maxRow, maxCol),
            child: image),
        clipper: PieceClipper(lastRow, lastCol, maxRow, maxCol),
      ),
    );
  }

  // Return a widget suitable for insertion into the listview.
  Widget buildListviewTarget() {
    return Container(
      key: Key('${widget.puzzlePiece.id.toString()}'),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.memory(widget.puzzlePiece.imageBytes, fit: BoxFit.fill),
      ),
    );
  }
}

// this class is used to clip the image to the puzzle piece path
class PieceClipper extends CustomClipper<Path> {
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;

  PieceClipper(this.row, this.col, this.maxRow, this.maxCol);

  @override
  Path getClip(Size size) {
    return getPiecePath(size, row, col, maxRow, maxCol);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// this class is used to draw a border around the clipped image
class PiecePainter extends CustomPainter {
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;

  PiecePainter(this.row, this.col, this.maxRow, this.maxCol);

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
