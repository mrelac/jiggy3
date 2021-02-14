import 'package:flutter/material.dart';
import 'package:jiggy3/models/puzzle_piece.dart';

/// This class is a widget that represents a single PuzzlePiece with path
/// (edge) cutouts, without Padding or Positioned/Stack properties. The idea
/// is to wrap this Piece in the appropriate widget for display on the palette
/// or in the listview.

typedef void OnPieceDropped(Piece piece, Offset topLeft);

class Piece extends StatefulWidget {
  final PuzzlePiece puzzlePiece;

  // GlobalKey to identify piece position in listview. NOTE: it does not work
  // to pass this key to the parent via Piece constructor super. It *does*,
  // however, work if you add the key to the ClipPath that gets returned.
  final Key key; // GlobalKey to identify piece position in listview

  Piece(this.puzzlePiece, this.key);

  Widget lvPiece(bool devIsLandscape, OnPieceDropped onPieceDropped) {
    final Widget clipPath = _clipPathImage();
    return Draggable<Piece>(
      child: _lvDragTarget(onPieceDropped),
      feedback: clipPath,
      childWhenDragging: Container(),
      data: this,
      affinity: devIsLandscape ? Axis.horizontal : Axis.vertical,
      onDraggableCanceled: (velocity, offset) {
        print('lvPiece: Drag was canceled. offset = $offset');
      },
    );
  }

  Widget _lvDragTarget(OnPieceDropped onPieceDropped) {
    return DragTarget<Piece>(
      builder: (context, ok, rejected) => _clipPathImage(),
      onWillAccept: (_) => true,
      onAcceptWithDetails: ((DragTargetDetails<Piece> dtd) {
        onPieceDropped(dtd.data, dtd.offset);
      }),
    );
  }

  Widget _clipPathImage() {
    return ClipPath(
      key: key,   // GlobalKey used to identify absolute position in lv
      child: Container(
        // FIXME get rid of this Padding if you don't need it.
        child: Padding(
          // padding: const EdgeInsets.all(4.0),
          padding: const EdgeInsets.all(0.0),

          // FIXME can this be puzzlePiece.image instead for consistency?
          // child: Image.memory(puzzlePiece.imageBytes, fit: BoxFit.fill),
          child: Image.memory(puzzlePiece.imageBytes),
        ),
      ),
      // clipper: PieceClipper(lastRow, lastCol, maxRow, maxCol),
    );
  }

  Widget playedPiece(Size devSize, OnPieceDropped onPieceDropped) {
    return Positioned(
      left: puzzlePiece.lastDx,
      top: puzzlePiece.lastDy,
      width: puzzlePiece.imageWidth,
      height: puzzlePiece.imageHeight,
      child: _playedPiece(devSize, onPieceDropped),
    );
  }

  Widget _playedPiece(Size devSize, OnPieceDropped onPieceDropped) {
    final Widget clipPath = _clipPathPainter(devSize);
    return Draggable<Piece>(
      child: _playedDragTarget(devSize, onPieceDropped),
      feedback: clipPath,
      childWhenDragging: Container(),
      data: this,
      onDraggableCanceled: (velocity, offset) {
        print('_playedPiece: Drag was canceled. offset = $offset');
      },
    );
  }

  Widget _playedDragTarget(Size devSize, OnPieceDropped onPieceDropped) {
    return DragTarget<Piece>(
      builder: (context, ok, rejected) => _clipPathPainter(devSize),
      onWillAccept: (_) => true,
      onAcceptWithDetails: ((DragTargetDetails<Piece> dtd) =>
          onPieceDropped(dtd.data, dtd.offset)),
    );
  }

  ClipPath _clipPathPainter(Size devSize) {
    return ClipPath(
      child: CustomPaint(
          foregroundPainter: PiecePainter(
              puzzlePiece.lastDy.toInt(),
              puzzlePiece.lastDx.toInt(),
              devSize.height.toInt(),
              devSize.width.toInt()),
          child: puzzlePiece.image),
      // clipper: PieceClipper(lastRow, lastCol, maxRow, maxCol),
    );
  }

  @override
  _PieceState createState() => _PieceState();

  @override
  String toStringShort() {
    return 'Piece{puzzlePiece: {$puzzlePiece}}}';
  }
}

class _PieceState extends State<Piece> {
  @override
  Widget build(BuildContext context) {
    return widget._clipPathImage();
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
