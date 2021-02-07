import 'package:flutter/material.dart';
import 'package:jiggy3/models/puzzle_piece.dart';

/// This class is a widget that represents a single PuzzlePiece with path
/// (edge) cutouts, without Padding or Positioned/Stack properties. The idea
/// is to wrap this Piece in the appropriate widget for display on the palette
/// or in the listview.

typedef void OnPieceDropped(Piece piece, Offset topLeft);

class Piece extends StatefulWidget {
  final PuzzlePiece puzzlePiece;
  final Size devSize;

  Piece(this.puzzlePiece, this.devSize);

  bool get devIsLandscape => devSize.width > devSize.height;

  Widget lvDraggable(Size devSize, OnPieceDropped onPieceDropped) {
    final Widget clipPath = _clipPath();
    return Draggable<Piece>(
      child: _lvDragTarget(onPieceDropped),
      feedback: clipPath,
      childWhenDragging: Container(),
      data: this,
      affinity: devIsLandscape ? Axis.horizontal : Axis.vertical,
      onDraggableCanceled: (velocity, offset) {
        print('Drag was canceled. offset = $offset');
      },
    );
  }

  Widget _lvDragTarget(OnPieceDropped onPieceDropped) {
    return DragTarget<Piece>(
      builder: (context, ok, rejected) => _clipPath(),
      onWillAccept: (_) => true,
      onAcceptWithDetails: ((DragTargetDetails<Piece> dtd) {
        onPieceDropped(this, dtd.offset);
      }),
    );
  }

  Widget _clipPath() {
    return ClipPath(
      child: Container(
        key: Key('${puzzlePiece.id.toString()}'),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.memory(puzzlePiece.imageBytes, fit: BoxFit.fill),
        ),
      ),
      // clipper: PieceClipper(lastRow, lastCol, maxRow, maxCol),
    );
  }

  Widget playedDraggable(OnPieceDropped onPieceDropped) {
    final Widget playedPositioned = _playedPositioned();
    return Draggable<Piece>(
        child: _playedDragTarget(onPieceDropped),
        feedback: playedPositioned,
        childWhenDragging: Container(),
        data: this);
  }

  Widget _playedDragTarget(OnPieceDropped onPieceDropped) {
    return DragTarget<Piece>(
      builder: (context, ok, rejected) => _playedPositioned(),
      onAcceptWithDetails: ((DragTargetDetails dtd) {
        onPieceDropped(this, dtd.offset);
      }),
      onWillAccept: (_) => true,
    );
  }

  Widget _playedPositioned() {
    return Positioned(
      left: puzzlePiece.lastTop,
      top: puzzlePiece.lastLeft,
      width: puzzlePiece.imageWidth,
      height: puzzlePiece.imageHeight,
      child: ClipPath(
        child: CustomPaint(
            foregroundPainter: PiecePainter(
                puzzlePiece.lastTop.toInt(),
                puzzlePiece.lastLeft.toInt(),
                devSize.height.toInt(),
                devSize.width.toInt()),
            child: puzzlePiece.image),
        // clipper: PieceClipper(lastRow, lastCol, maxRow, maxCol),
      ),
    );
  }

  @override
  _PieceState createState() => _PieceState();

  @override
  String toStringShort() {
    return 'Piece{puzzlePiece: {$puzzlePiece}, devSize: {$devSize]}}';
  }
}

class _PieceState extends State<Piece> {
  @override
  Widget build(BuildContext context) {
    return widget._clipPath();
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
