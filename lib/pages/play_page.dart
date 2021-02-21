import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/blocs/puzzle_bloc.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';
import 'package:jiggy3/models/rc.dart';
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

  bool get imageIsLandscape => !imageIsPortrait;

  bool get imageIsPortrait => imgSize.width < imgSize.height;

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
      imageIsLandscape && devIsLandscape
          ? dW - eW
          : imageIsLandscape && devIsPortrait
              ? dW
              : imageIsPortrait && devIsLandscape
                  ? _imgSize.width
                  : imageIsPortrait && devIsPortrait
                      ? dW
                      : null;

  double get iH => // Image Height
      imageIsLandscape && devIsLandscape
          ? dH
          : imageIsLandscape && devIsPortrait
              ? _imgSize.height
              : imageIsPortrait && devIsLandscape
                  ? dH
                  : imageIsPortrait && devIsPortrait
                      ? dH - eH
                      : null;

  EdgeInsets get iP => // Image Padding
      imageIsLandscape && devIsLandscape
          ? EdgeInsets.zero
          : imageIsLandscape && devIsPortrait
              ? EdgeInsets.only(top: dH - eH - iH)
              : imageIsPortrait && devIsLandscape
                  ? EdgeInsets.only(left: dW - eW - iW)
                  : imageIsPortrait && devIsPortrait
                      ? EdgeInsets.zero
                      : null;

  double get lW => // Listview Width
      imageIsLandscape && devIsLandscape
          ? eW
          : imageIsLandscape && devIsPortrait
              ? dW
              : imageIsPortrait && devIsLandscape
                  ? eW
                  : imageIsPortrait && devIsPortrait
                      ? dW - eW
                      : null;

  double get lH => // Listview Height
      imageIsLandscape && devIsLandscape
          ? dH - eH
          : imageIsLandscape && devIsPortrait
              ? eH
              : imageIsPortrait && devIsLandscape
                  ? dH
                  : imageIsPortrait && devIsPortrait
                      ? eH
                      : null;

  Color _colourValue;
  Puzzle puzzle;
  ImageProvider _imgProvider;
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
    Utils.setOrientations(imageIsLandscape);
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        body: _buildBody(),
        floatingActionButton: _paletteFabMenu,
      ),
    );
  }

  Widget _buildBody() {
    final w = <Widget>[];

    return Stack(
        children: w
          ..add(imageIsLandscape && devIsLandscape
              ? _landXland()
              : imageIsLandscape && devIsPortrait
                  ? _landXport()
                  : imageIsPortrait && devIsLandscape
                      ? _portXland()
                      : imageIsPortrait && devIsPortrait
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
      piece.puzzlePiece.last = null;

      // Insert piece into listview at current location
      Utils.printListviewPieces(_lvPieces);
      int insertAt =
          Utils.findClosestLvElement(_lvPieces, isVerticalListview, topLeft);
// print('Inserting at $insertAt');
      setState(() {
        _lvPieces.insert(insertAt, piece);
      });
    } else {
      // Translate offset to the closest RC.
      RC rc = findClosest(piece.puzzlePiece, topLeft);
      if (rc == piece.puzzlePiece.home) {
        piece.puzzlePiece.last = piece.puzzlePiece.home;
        piece.puzzlePiece.locked = true;
        puzzle.numLocked++;
        await BlocProvider.of<PuzzleBloc>(context)
            .updatePuzzlePieceLocked(piece.puzzlePiece, puzzle.numLocked);
        await BlocProvider.of<PuzzleBloc>(context)
            .updatePuzzle(puzzle.id, numLocked: puzzle.numLocked);
        print('Piece is now LOCKED!!');
      } else {
        piece.puzzlePiece.last = rc;
      }

      // If this was the last (locked) piece, the game is over. End the game.
      print('numLocked = ${puzzle.numLocked}');
      if (puzzle.numLocked == puzzle.maxPieces) {
        print('GAME OVER!');
        await BlocProvider.of<PuzzleBloc>(context).resetPuzzle(puzzle);
      }

      setState(() {
        puzzle.numLocked = puzzle.numLocked;
        _playedPieces.add(piece);
      });
    }

    await BlocProvider.of<PuzzleBloc>(context)
        .updatePuzzlePiecePosition(piece.puzzlePiece);
  }

  // Find the closest RC (column/row) to offset.
  RC findClosest(PuzzlePiece pp, Offset offset) {
    int dxF = (offset.dx / pp.imageWidth).floor();
    int dxC = (offset.dx / pp.imageWidth).ceil();
    int colF = (offset.dx - (dxF * pp.imageWidth)).abs().toInt();
    int colC = (offset.dx - (dxC * pp.imageWidth)).abs().toInt();
    int col = colF < colC ? dxF : dxC;

    int dyF = (offset.dy / pp.imageHeight).floor();
    int dyC = (offset.dy / pp.imageHeight).ceil();
    int rowF = (offset.dy - (dyF * pp.imageHeight)).abs().toInt();
    int rowC = (offset.dy - (dyC * pp.imageHeight)).abs().toInt();
    int row = rowF < rowC ? dyF : dyC;

    final rc = RC(row: row, col: col);
    print('closest RC = $rc');
    return rc;
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

  Future<bool> _onWillPop() {
    Utils.setOrientations();
    Navigator.pop(context, puzzle);
    return Future.value(false);
  }
}
