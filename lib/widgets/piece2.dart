import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jiggy3/models/puzzle_piece.dart';
import 'package:path_drawing/path_drawing.dart';

class Piece2 extends StatefulWidget {
  final PuzzlePiece puzzlePiece;
  final Image image;
  final Size imageSize;
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;

  Piece2(
      {Key key,
        @required this.image,
        @required this.imageSize,
        @required this.row,
        @required this.col,
        @required this.maxRow,
        @required this.maxCol,
        @required this.puzzlePiece})
      : super(key: key);

  @override
  Piece2State createState() {
    return new Piece2State();
  }
}

class Piece2State extends State<Piece2> {
  // double top;
  // double left;

  @override
  Widget build(BuildContext context) {
    // FIXME
    // final imageWidth = MediaQuery.of(context).size.width;
    // final imageHeight = MediaQuery.of(context).size.height * MediaQuery.of(context).size.width / widget.imageSize.width;

    final imageWidth = widget.imageSize.width;
    final imageHeight = widget.imageSize.height;

    final pieceWidth = imageWidth / widget.maxCol;
    final pieceHeight = imageHeight / widget.maxRow;

    // if (top == null) {
    //   top = Random().nextInt((imageHeight - pieceHeight).ceil()).toDouble();
    //   top -= widget.row * pieceHeight;
    // }
    // if (left == null) {
    //   left = Random().nextInt((imageWidth - pieceWidth).ceil()).toDouble();
    //   left -= widget.col * pieceWidth;
    // }

    return Draggable<Piece2>(
      child: _clippedPath(),
      feedback: _clippedPath(),
      childWhenDragging: Container(),
      data: widget,
      onDraggableCanceled: (velocity, offset) {
        print('Piece2.build(): Drag was canceled. offset = $offset');
      },
    );


    // return Positioned(
    //   top: top,
    //   left: left,
    //   width: imageWidth,
    //   child: ClipPath(
    //     child: CustomPaint(
    //         foregroundPainter: PuzzlePiecePainter(widget.row, widget.col, widget.maxRow, widget.maxCol),
    //         child: widget.image
    //     ),
    //     clipper: PuzzlePieceClipper(widget.row, widget.col, widget.maxRow, widget.maxCol),
    //   ),
    // );
  }

  Widget _clippedPath() {
    return ClipPath(
      child: CustomPaint(
          foregroundPainter: PuzzlePiecePainter(widget.row, widget.col, widget.maxRow, widget.maxCol),
          child: widget.image
      ),
      clipper: PuzzlePieceClipper(widget.row, widget.col, widget.maxRow, widget.maxCol),
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
// FIXME get rid of these number comments when it's debugged and working.
Path getPiecePath(Size size, int row, int col, int maxRow, int maxCol) {
  final width = size.width / maxCol;    // 256 (SHOULD BE 236!)

  final height = size.height / maxRow;  // 256
  final offsetX = col * width;          // 0
  final offsetY = row * height;         // 256
  final bumpSize = height / 4;          // 64

  var path = Path();
  path.moveTo(offsetX, offsetY);

  if (row == 0) {
    // top side piece
    path.lineTo(offsetX + width, offsetY);
  } else {
    // top bump
    path.lineTo(offsetX + width / 3, offsetY);

    _topBump(path, offsetX, width, offsetY, bumpSize);

    path.lineTo(offsetX + width, offsetY);
  }

  if (col == maxCol - 1) {
    // right side piece
    path.lineTo(offsetX + width, offsetY + height);
  } else {
    // right bump
    path.lineTo(offsetX + width, offsetY + height / 3);

    _rightBump(path, offsetX, width, bumpSize, offsetY, height);

    path.lineTo(offsetX + width, offsetY + height);
  }

  _bottomCut1(path, bumpSize, offsetX, offsetY, width, height, row, col, maxRow);
  // if (row == maxRow - 1) {
  //   // bottom side piece
  //   path.lineTo(offsetX, offsetY + height);
  // } else {
  //   // bottom bump
  //   path.lineTo(offsetX + width / 3 * 2, offsetY + height);
  //
  //   _bottomBump(path, offsetX, width, offsetY, height, bumpSize);
  //
  //   path.lineTo(offsetX, offsetY + height);
  // }

  if (col == 0) {
    // left side piece
    path.close();
  } else {
    // left bump
    path.lineTo(offsetX, offsetY + height / 3 * 2);

    _leftBump(path, offsetX, bumpSize, offsetY, height);

    path.close();
  }



  // String path1 = 'M100,200 L3,4';
  // String path2 = 'm18 11.8a.41.41 0 0 1 .24.08l.59.43h.05.72a.4.4 0 0 1 .39.28l.22.69a.08.08 0 0 0 0 0l.58.43a.41.41 0 0 1 .15.45l-.22.68a.09.09 0 0 0 0 .07l.22.68a.4.4 0 0 1 -.15.46l-.58.42a.1.1 0 0 0 0 0l-.22.68a.41.41 0 0 1 -.38.29h-.79l-.58.43a.41.41 0 0 1 -.24.08.46.46 0 0 1 -.24-.08l-.58-.43h-.06-.72a.41.41 0 0 1 -.39-.28l-.22-.68a.1.1 0 0 0 0 0l-.58-.43a.42.42 0 0 1 -.15-.46l.23-.67v-.02l-.29-.68a.43.43 0 0 1 .15-.46l.58-.42a.1.1 0 0 0 0-.05l.27-.69a.42.42 0 0 1 .39-.28h.78l.58-.43a.43.43 0 0 1 .25-.09m0-1a1.37 1.37 0 0 0 -.83.27l-.34.25h-.43a1.42 1.42 0 0 0 -1.34 1l-.13.4-.35.25a1.42 1.42 0 0 0 -.51 1.58l.13.4-.13.4a1.39 1.39 0 0 0 .52 1.59l.34.25.13.4a1.41 1.41 0 0 0 1.34 1h.43l.34.26a1.44 1.44 0 0 0 .83.27 1.38 1.38 0 0 0 .83-.28l.35-.24h.43a1.4 1.4 0 0 0 1.33-1l.13-.4.35-.26a1.39 1.39 0 0 0 .51-1.57l-.13-.4.13-.41a1.4 1.4 0 0 0 -.51-1.56l-.35-.25-.13-.41a1.4 1.4 0 0 0 -1.34-1h-.42l-.34-.26a1.43 1.43 0 0 0 -.84-.28z';
  //
  //
  // print('path1:');
  // Path p = parseSvgPathData(path1);
  // PathMetrics pm = p.computeMetrics();
  // printPm(pm, row, col);
  //
  // print(' ');
  // print('path2:');
  // p = parseSvgPathData(path2);
  // pm = p.computeMetrics();
  // printPm(pm, row, col);
  // print(' ');
  // print(' ');

  return path;
}

void _topBump(Path path, double offsetX, double width, double offsetY, double bumpSize) {
  path.cubicTo(
      offsetX + width / 6,
      offsetY - bumpSize,
      offsetX + width / 6 * 5,
      offsetY - bumpSize,
      offsetX + width / 3 * 2,
      offsetY);
}

void _rightBump(Path path, double offsetX, double width, double bumpSize, double offsetY, double height) {
  path.cubicTo(
      offsetX + width - bumpSize,    // '+' here ...
      offsetY + height / 6,
      offsetX + width - bumpSize,    // and '+' here make a bump.
      offsetY + height / 6 * 5,
      offsetX + width,
      offsetY + height / 3 * 2);
}

void _bottomBump(Path path, double offsetX, double width, double offsetY, double height, double bumpSize) {
  path.cubicTo(
      offsetX + width / 6 * 5,
      offsetY + height - bumpSize,
      offsetX + width / 6,
      offsetY + height - bumpSize,
      offsetX + width / 3,
      offsetY + height);
}

void _leftBump(Path path, double offsetX, double bumpSize, double offsetY, double height) {
  path.cubicTo(
      offsetX - bumpSize,
      offsetY + height / 6 * 5,
      offsetX - bumpSize,
      offsetY + height / 6,
      offsetX,
      offsetY + height / 3);
}

printPm(PathMetrics pms, int row, int col) {
  // print('There are ${pms.length} PathMetric segments in path for ($row, $col)');
  // print('toString(): ${pms.toString()}');
  // List<PathMetric> pml = pms.toList();
  // int i = 0;
  // for (PathMetric pm in pml) {
  // // for (int i = 0; i < pms.length; i++) {
  // //   PathMetric pm = pms.elementAt(i);
  //   print('  pm[$i]: ${pm}. length: ${pm.length}. contourIndex: ${pm.contourIndex}. toString(): ${pm.toString()}');
  //   print('  path[$i](0,0, 1024.0): ${pm.extractPath(0.0, 1024.0)}');
  //   i++;
  // }
}


void _bottomBump2(Path path, double bumpSize, double offsetX, double offsetY,
    double width, double height, int row, int maxRow) {
  if (row == maxRow - 1) {

    // Edge piece
    path.lineTo(offsetX, offsetY + height);

  } else {
    // line from start to cut
    path.lineTo(offsetX + width / 3 * 2, offsetY + height);

    // cut
    path.cubicTo(
        offsetX + width / 6 * 5,
        offsetY + height + bumpSize,
        offsetX + width / 6,
        offsetY + height + bumpSize,
        offsetX + width / 3,
        offsetY + height);

    // line from cut to end
    path.lineTo(offsetX, offsetY + height);
  }
}


void _bottomCut2(Path path, double bumpSize, double offsetX, double offsetY,
    double width, double height, int row, int col, int maxRow) {

  double lx1 = offsetX;
  double ly1 = offsetY + height;
  double lx2 = offsetX;
  double ly2 = offsetY + height;

  double cx1 = offsetX + width / 6 * 5;
  double cy1 = offsetY + height - bumpSize;
  double cx2 = offsetX + width / 6;
  double cy2 = offsetY + height - bumpSize;
  double ofx = offsetX + width / 3;
  double ofy = offsetY + height;



  if (row == maxRow - 1) {
    // bottom side piece
    path.lineTo(lx1, ly1);
  } else {
    // bottom bump
    path.lineTo(offsetX + width / 3 * 2, offsetY + height);
    path.cubicTo(cx1, cy1, cx2, cy2, ofx, ofy
        // offsetX + width / 6 * 5,
        // offsetY + height + bumpSize,
        // offsetX + width / 6,
        // offsetY + height + bumpSize,
        // offsetX + width / 3,
        // offsetY + height
    );
    path.lineTo(lx2, ly2);
  }
}

void _bottomCut1(Path path, double bumpSize, double offsetX, double offsetY,
    double width, double height, int row, int col, int maxRow) {

  // Edge piece
  double lx1 = offsetX;
  double ly1 = offsetY + height;


   // line from start to cut
  double lx2 = offsetX + width / 3 * 2;
  double ly2 = offsetY + height;

  // cut
  double cx1 = offsetX + width / 6 * 5;
  double cy1 = offsetY + height - bumpSize;
  double cx2 = offsetX + width / 6;
  double cy2 = offsetY + height - bumpSize;
  double cx3 = offsetX + width / 3;
  double cy3 = offsetY + height;


  // line from cut to end
  double ofx = offsetX;
  double ofy = offsetY + height;

  final String dEdge = 'M $offsetX $offsetY   L $lx1 $ly1';
  final String d = '''
M $offsetX $offsetY   L $lx2 $ly2   C $cx1 $cy1 $cx2 $cy2 $cx3 $cy3   L $ofx $ofy
  ''';

  print('($row,$col) d: $d');

  Path segment = parseSvgPathData(row == maxRow - 1 ? dEdge : d);
  segment = parseSvgPathData(row == maxRow - 1 ? dEdge : d);
  // segment.extendWithPath(path, Offset(offsetX, offsetY));
  path.extendWithPath(segment, Offset(0, 0));

  // Path.combine(PathOperation.union, path, segment);
}