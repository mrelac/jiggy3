import 'dart:math';

import 'package:jiggy3/widgets/piece2.dart';


class ClipGenerator {
  final Piece2 piece;
  // final double _bs = 2.4;
  final double _bs = 3.4;

  ClipGenerator(this.piece);

  String generateTop(double width, double height) {
    return _generateTop(width, height);
  }

  String generateRight(double width, double height) {
    return _generateRight(width, height);
  }

  String generateBottom(double width, double height) {
    return _generateBottom(width, height);
  }

  String generateLeft(double width, double height) {
    return _generateLeft(width, height);
  }

  String generateTopB(double width, double height) {
    return _generateTopBump(width, height);
  }
  String generateRightB(double width, double height) {
    return _generateRightBump(width, height);
  }
  String generateBottomB(double width, double height) {
    return _generateBottomBump(width, height);
  }
  String generateLeftB(double width, double height) {
    return _generateLeftBump(width, height);
  }


  String _generateTopBump(double w, double h) {
    double beforeC = w / 3;
    double afterC = w / 3;
    double p1 = 0;
    double p2 = -(w / _bs);
    double p3 = w / 3;
    double p4 = -(w / _bs);
    double p5 = w / 3;
    double p6 = 0;
    // String bumpC = '0 -2 2 -2 2 0';
    String bumpC = '$p1 $p2 $p3 $p4 $p5 $p6';

    print('_bs: $_bs. p2 = $p2. p4 = $p4');

    return 'h $beforeC c $bumpC h $afterC';
  }

  String _generateTopCut(double w, double h) {
    double beforeC = w / 3;
    double afterC = w / 3;
    double p1 = 0;
    double p2 = w / _bs;
    double p3 = w / 3;
    double p4 = w / _bs;
    double p5 = w / 3;
    double p6 = 0;
    // String cutC  = '0  2 2  2 2 0';
    String cutC = '$p1 $p2 $p3 $p4 $p5 $p6';
    return 'h $beforeC c $cutC h $afterC';
  }

  String _generateRightBump(double w, double h) {
    double beforeC = h / 3;
    double afterC = h / 3;
    double p1 = w / _bs;
    double p2 = 0;
    double p3 = w / _bs;
    double p4 = w / 3;
    double p5 = 0;
    double p6 = w / 3;
    // String bumpC =  '2 0  2 2 0 2';
    String bumpC = '$p1 $p2 $p3 $p4 $p5 $p6';
    return 'v $beforeC c $bumpC v $afterC';
  }

  String _generateRightCut(double w, double h) {
    double beforeC = w / 3;
    double afterC = w / 3;
    double p1 = -(w / _bs);
    double p2 = 0;
    double p3 = -(w / _bs);
    double p4 = w / 3;
    double p5 = 0;
    double p6 = w / 3;
    // String cutC  = '-2 0 -2 2 0 2';
    String cutC = '$p1 $p2 $p3 $p4 $p5 $p6';
    return 'v $beforeC c $cutC v $afterC';
  }

  String _generateBottomBump(double w, double h) {
    double beforeC = -(w / 3);
    double afterC = -(w / 3);
    double p1 = 0;
    double p2 = w / _bs;
    double p3 = -(w / 3);
    double p4 = w / _bs;
    double p5 = -(w / 3);
    double p6 = 0;
    // String bumpC = '0  2 -2  2 -2 0';
    String bumpC = '$p1 $p2 $p3 $p4 $p5 $p6';
    return 'h $beforeC c $bumpC h $afterC';
  }

  String _generateBottomCut(double w, double h) {
    double beforeC = -(w / 3);
    double afterC = -(w / 3);
    double p1 = 0;
    double p2 = -(w / _bs);
    double p3 = -(w / 3);
    double p4 = -(w / _bs);
    double p5 = -(w / 3);
    double p6 = 0;
    // String cutC  = '0 -2 -2 -2 -2 0';
    String cutC = '$p1 $p2 $p3 $p4 $p5 $p6';
    return 'h $beforeC c $cutC h $afterC';
  }

  String _generateLeftBump(double w, double h) {
    double beforeC = -(h / 3);
    double afterC = -(h / 3);
    double p1 = -(w / _bs);
    double p2 = 0;
    double p3 = -(w / _bs);
    double p4 = -(w / 3);
    double p5 = 0;
    double p6 = -(w / 3);
    // String bumpC = '-2 0 -2 -2 0 -2';
    String bumpC = '$p1 $p2 $p3 $p4 $p5 $p6';
    return 'v $beforeC c $bumpC v $afterC';
  }

  String _generateLeftCut(double w, double h) {
    double beforeC = -(h / 3);
    double afterC = -(h / 3);
    double p1 = w / _bs;
    double p2 = 0;
    double p3 = w / _bs;
    double p4 = -(w / 3);
    double p5 = 0;
    double p6 = -(w / 3);
    // String cutC  = ' 2 0  2 -2 0 -2';
    String cutC = '$p1 $p2 $p3 $p4 $p5 $p6';
    return 'v $beforeC c $cutC v $afterC';
  }

  String _generateTop(double w, double h) {
    if (piece.puzzlePiece.home.row == 0) {
      return 'h $w';
    } else {
      var rng = new Random();
      return rng.nextBool() ? _generateTopBump(w, h) : _generateTopCut(w, h);
    }
  }

  String _generateRight(double w, double h) {
    if (piece.puzzlePiece.home.col == piece.maxCol - 1) {
      return 'v $h';
    } else {
      var rng = new Random();
      return rng.nextBool()
          ? _generateRightBump(w, h)
          : _generateRightCut(w, h);
    }
  }

  String _generateBottom(double w, double h) {
    if (piece.puzzlePiece.home.row == piece.maxRow - 1) {
      return 'h -$w';
    } else {
      var rng = new Random();
      return rng.nextBool()
          ? _generateBottomBump(w, h)
          : _generateBottomCut(w, h);
    }
  }

  String _generateLeft(double w, double h) {
    if (piece.puzzlePiece.home.col == 0) {
      return 'v -$h';
    } else {
      var rng = new Random();
      return rng.nextBool() ? _generateLeftBump(w, h) : _generateLeftCut(w, h);
    }
  }
}
