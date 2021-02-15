import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/blocs/puzzle_bloc.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';
import 'package:jiggy3/services/utils.dart';
import 'package:jiggy3/widgets/palette_fab_menu.dart';
import 'package:jiggy3/widgets/piece.dart';

const double eW = 80.0; // Element width including padding
const double eH = 80.0; // Element height including padding
const double fW = 80.0; // fab width including padding
const double fH = 80.0; // fab height including padding

class PlayPage extends StatefulWidget {
  final Puzzle puzzle;

  PlayPage(this.puzzle);

  @override
  _PlayPageState createState() => _PlayPageState();

  static double get elWidth => eW;

  static double get elHeight => eH;
}

class _PlayPageState extends State<PlayPage> {
  Size _imgSize;

  PaletteFabMenu _paletteFabMenu;

  Size get imgSize => _imgSize;

  bool get imgIsLandscape => !imgIsPortrait;

  bool get imgIsPortrait => imgSize.width < imgSize.height;

  Size get devSize => MediaQuery.of(context).size;

  bool get devIsPortrait =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  bool get devIsLandscape => !devIsPortrait;

  // The listview scrollbar always spans the short side of the device
  // (e.g. if dev is landscape, the sb is vertical; else it is horizontal)
  bool get isHorizontalListview => devIsPortrait;

  bool get isVerticalListview => !isHorizontalListview;

  double get dW => devSize.width;

  double get dH => devSize.height;

  double get iW => // Image Width
      imgIsLandscape && devIsLandscape
          ? dW - eW
          : imgIsLandscape && devIsPortrait
              ? dW
              : imgIsPortrait && devIsLandscape
                  ? _imgSize.width
                  : imgIsPortrait && devIsPortrait
                      ? dW
                      : null;

  double get iH => // Image Height
      imgIsLandscape && devIsLandscape
          ? dH
          : imgIsLandscape && devIsPortrait
              ? _imgSize.height
              : imgIsPortrait && devIsLandscape
                  ? dH
                  : imgIsPortrait && devIsPortrait
                      ? dH - eH
                      : null;

  EdgeInsets get iP => // Image Padding
      imgIsLandscape && devIsLandscape
          ? EdgeInsets.zero
          : imgIsLandscape && devIsPortrait
              ? EdgeInsets.only(top: dH - eH - iH)
              : imgIsPortrait && devIsLandscape
                  ? EdgeInsets.only(left: dW - eW - iW)
                  : imgIsPortrait && devIsPortrait
                      ? EdgeInsets.zero
                      : null;

  double get lW => // Listview Width
      imgIsLandscape && devIsLandscape
          ? eW
          : imgIsLandscape && devIsPortrait
              ? dW
              : imgIsPortrait && devIsLandscape
                  ? eW
                  : imgIsPortrait && devIsPortrait
                      ? dW - eW
                      : null;

  double get lH => // Listview Height
      imgIsLandscape && devIsLandscape
          ? dH - eH
          : imgIsLandscape && devIsPortrait
              ? eH
              : imgIsPortrait && devIsLandscape
                  ? dH
                  : imgIsPortrait && devIsPortrait
                      ? eH
                      : null;

  Color _colourValue;
  Puzzle puzzle;
  ImageProvider _imgProvider;
  final double _lockFactor =
      0.333; // Piece is considered 'locked' if dropped within this factor.
  final GlobalKey _lvKey = GlobalKey();
  final _lvPieces = <Piece>[];
  final _playedPieces = <Piece>[];
  ValueNotifier<double> _opacityFactor;

  void changeColor(Color color) {
    setState(() {
      _colourValue = color;
      widget.puzzle.imageColour = color;
      _updatePuzzleControls();
    });
  }

  @override
  void initState() {
    super.initState();

    BlocProvider.of<PuzzleBloc>(context).loadPuzzlePieces();
    BlocProvider.of<PuzzleBloc>(context)
        .puzzlePiecesStream
        .listen((pieces) => _loadPieces(pieces));

    puzzle = widget.puzzle;
    _imgSize = Size(widget.puzzle.image.width, widget.puzzle.image.height);
    _imgProvider = widget.puzzle.image.image;
    _colourValue = puzzle.imageColour;
    _opacityFactor = new ValueNotifier<double>(puzzle.imageOpacity);
    _paletteFabMenu = PaletteFabMenu(_colourValue, _opacityFactor,
        onColourChanged: onColourChanged,
        onColourChangeEnd: onColourChangeEnd,
        onImageOpacityChanged: onImageOpacityChanged,
        onImageOpacityChangeEnd: onImageOpacityChangEnd);
  }

  void _loadPieces(List<PuzzlePiece> pieces) {
    final lvPieces = <Piece>[];
    final playedPieces = <Piece>[];
    pieces.forEach((puzzlePiece) {
      if (puzzlePiece.lastDy != null) {
        playedPieces.add(Piece(puzzlePiece, GlobalKey()));
      } else {
        lvPieces.add(Piece(puzzlePiece, GlobalKey()));
      }
    });
    setState(() {
      _lvPieces.addAll(lvPieces);
      _playedPieces.addAll(playedPieces);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: _buildBody(),
      floatingActionButton: _paletteFabMenu,
    );
  }

  Widget _buildBody() {
    final w = <Widget>[];

    return Stack(
        children: w
          ..add(imgIsLandscape && devIsLandscape
              ? _landXland()
              : imgIsLandscape && devIsPortrait
                  ? _landXport()
                  : imgIsPortrait && devIsLandscape
                      ? _portXland()
                      : imgIsPortrait && devIsPortrait
                          ? _portXport()
                          : null)
          ..addAll(_draggablePlayedPieces()));
  }

  List<Widget> _draggablePlayedPieces() {
    final w = <Widget>[];
    _playedPieces
        .forEach((piece) => w.add(piece.playedPiece(devSize, onPieceDropped)));
    return w;
  }

  void onPieceDropped(Piece piece, Offset topLeft) async {
    print(
        'PlayPage.onPieceDrop(): piece: $piece, topLeft: $topLeft. droppedInLv: ${_droppedInListView(piece, topLeft)}');

    // Remove from _lvPieces and _playedPieces.
    _lvPieces.remove(piece);
    _playedPieces.remove(piece);

    if (_droppedInListView(piece, topLeft)) {
      piece.puzzlePiece.lastDx = null;
      piece.puzzlePiece.lastDy = null;

      // Insert piece into listview at current location
      Utils.printListviewPieces(_lvPieces);
      int insertAt =
          Utils.findClosestLvElement(_lvPieces, isVerticalListview, topLeft);
// print('Inserting at $insertAt');
      setState(() {
        _lvPieces.insert(insertAt, piece);
      });
    } else {
      // If topLeft is within _lockedFactor of home then lock piece.
      double pieceW = piece.puzzlePiece.imageWidth;
      double pieceH = piece.puzzlePiece.imageHeight;
      double homeDx = piece.puzzlePiece.homeDx;
      double homeDy = piece.puzzlePiece.homeDy;
      double dropDx = topLeft.dx;
      double dropDy = topLeft.dy;
      double diffDx = (dropDx - homeDx).abs();
      double diffDy = (dropDy - homeDy).abs();
      double lfDx = pieceW * _lockFactor;
      double lfDy = pieceH * _lockFactor;

      print('diffDx: $diffDx, diffDy: $diffDy, lfDx: $lfDx, lfDy: $lfDy');

      if (((dropDx - homeDx).abs() < pieceW * _lockFactor) &&
          ((dropDy - homeDy).abs() < pieceH * _lockFactor)) {
        piece.puzzlePiece.lastDx = homeDx;
        piece.puzzlePiece.lastDy = homeDy;
        piece.puzzlePiece.locked = true;
        await BlocProvider.of<PuzzleBloc>(context)
            .updatePuzzlePieceLocked(piece.puzzlePiece);
        print('Piece is now LOCKED!!');
      } else {
        piece.puzzlePiece.lastDx = topLeft.dx;
        piece.puzzlePiece.lastDy = topLeft.dy;
      }

      // If this was the last (locked) piece, the game is over. End the game.
      print('numLocked = ${puzzle.numLocked}');
      if (puzzle.numLocked == puzzle.maxPieces) {
        print('GAME OVER!');
      }

      setState(() {
        _playedPieces.add(piece);
      });
    }

    await BlocProvider.of<PuzzleBloc>(context)
        .updatePuzzlePiecePosition(piece.puzzlePiece);
  }

  void onColourChanged(Color colour) {
    setState(() {
      _colourValue = colour;
      widget.puzzle.imageColour = colour;
    });
  }

  void onColourChangeEnd(Color colour) {
    _updatePuzzleControls();
  }

  void onImageOpacityChanged(double value) {
    setState(() {
      _colourValue = Color.fromRGBO(
          _colourValue.red, _colourValue.green, _colourValue.blue, value);
      _opacityFactor.value = value;
      widget.puzzle.imageOpacity = value;
    });
  }

  void onImageOpacityChangEnd(double value) {
    print('Done changing slider. value: $value');
    _updatePuzzleControls();
  }

  // Build imgLandscape x devLandscape layout
  Widget _landXland() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _puzzleImage(),
      _listView(),
    ]);
  }

  // Build imgLandscape x devPortrait layout
  Widget _landXport() {
    return Column(children: [
      _puzzleImage(),
      _listView(),
    ]);
  }

  // Build ingPortrait x devLandscape layout
  Widget _portXland() {
    return Row(children: [
      _puzzleImage(),
      _listView(),
    ]);
  }

  // Build imgPortrait x devPortrait layout
  Widget _portXport() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _puzzleImage(),
      _listView(),
    ]);
  }

  _fullImageContainer() {
    return Container(
        width: iW,
        height: iH,
        padding: iP,
        child: Image(
          color: Color.fromRGBO(
              widget.puzzle.imageColour.red,
              widget.puzzle.imageColour.green,
              widget.puzzle.imageColour.blue,
              _opacityFactor.value),
          colorBlendMode: BlendMode.modulate,
          fit: BoxFit.fill, // This stretches the image to fill image container
          image: _imgProvider,
        ));
  }

  Widget _puzzleImage() {
    return DragTarget<Piece>(
      builder: (context, ok, rejected) => _fullImageContainer(),
      onAcceptWithDetails: ((DragTargetDetails<Piece> dtd) {
        onPieceDropped(dtd.data, dtd.offset);
      }),
      onWillAccept: (_) => true,
    );
  }

  Widget _listView() {
    return DragTarget<Piece>(
        builder: (context, ok, rejected) => _listViewContainer(),
        onWillAccept: (_) => true,
        onAcceptWithDetails: ((DragTargetDetails<Piece> dtd) {
          onPieceDropped(dtd.data, dtd.offset);
        }));
  }

  Widget _listViewContainer() {
    return Container(
        color: _colourValue, // Background colour between pieces
        width: lW,
        height: lH,
        child: ListView.builder(
            padding: EdgeInsets.zero,
            key: _lvKey,
            cacheExtent: 1500,
            scrollDirection: devIsLandscape ? Axis.vertical : Axis.horizontal,
            itemCount: _lvPieces.length,
            itemBuilder: (context, index) =>
                _lvPieces[index].lvPiece(devIsLandscape, onPieceDropped)));
  }

  bool _droppedInListView(Piece piece, Offset piecePos) {
    Offset lvPos = Utils.getPosition(_lvKey);
    Size lvSize = Utils.getSize(_lvKey);
    if (lvSize.width < lvSize.height) {
      // vertical listview
      return piecePos.dx + (piece.puzzlePiece.imageWidth / 2) >= lvPos.dx
          ? true
          : false;
    } else {
      // horizontal listview
      return piecePos.dy + (piece.puzzlePiece.imageHeight) >= lvPos.dy
          ? true
          : false;
    }
  }

  void _updatePuzzleControls() {
    BlocProvider.of<PuzzleBloc>(context).updatePuzzle(widget.puzzle.id,
        imageColour: puzzle.imageColour, imageOpacity: puzzle.imageOpacity);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
