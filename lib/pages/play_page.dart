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
        playedPieces.add(Piece(puzzlePiece, puzzle.maxRc, GlobalKey()));
      } else {
        lvPieces.add(Piece(puzzlePiece, puzzle.maxRc, GlobalKey()));
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

  Stack _stack;

  Widget _buildBody() {
    _stack = _buildStack();
    return _stack;
  }

  Stack _buildStack() {
    return Stack(
        children: <Widget>[]
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

  // The locked pieces must go at the bottom of the stack (e.g. the first
  // elements in the array) so that non-homed pieces already in the locked
  // piece's place can be moved; else they will be trapped and can never be
  // moved.
  List<Widget> _draggablePlayedPieces() {
    _playedPieces..sort((p1, p2) => p2.puzzlePiece.isLocked ? 1 : -1);
    return _playedPieces
        .map((piece) => piece.playedPiece(devSize, onPieceDropped))
        .toList();
  }

  void onPieceDropped(Piece piece, Offset topLeft) async {
    bool isDroppedInLv = _isDroppedInListView(piece, topLeft);
    print('piece: $piece, topLeft: $topLeft. isDroppedInLv: $isDroppedInLv');

    // Remove from _lvPieces and _playedPieces.
    _lvPieces.remove(piece);
    _playedPieces.remove(piece);

    if (isDroppedInLv) {
      _droppedInLv(piece, topLeft);
    } else {
      await _droppedOnPalette(piece, topLeft);
    }
  }

  Future<void> _droppedOnPalette(Piece piece, Offset topLeft) async {
    // Constrain topLeft to the screen dimensions so pieces don't disappear.
    double dy = topLeft.dy < 0 ? 0 : topLeft.dy;
    dy = dy > devSize.height - piece.puzzlePiece.imageHeight ? devSize.height - piece.puzzlePiece.imageHeight : dy;
    double dx = topLeft.dx < 0 ? 0 : topLeft.dx;
    dx = dx > devSize.width - piece.puzzlePiece.imageWidth ? devSize.width - piece.puzzlePiece.imageWidth : dx;
    topLeft = Offset(dx, dy);

    // Translate offset to the closest RC.
    // Set instance variables. Then setState. Finally, update database.
    piece.puzzlePiece.last = findClosest(piece.puzzlePiece, topLeft);
    if (piece.puzzlePiece.last == piece.puzzlePiece.home) {
      piece.puzzlePiece.isLocked = true;
      puzzle.numLocked = puzzle.numLocked + 1;
      setState(() {
        piece.puzzlePiece.isLocked = true;
        puzzle.numLocked = puzzle.numLocked;
      });
      print(
          'piece ${piece.puzzlePiece.id} at ${piece.puzzlePiece.last} is LOCKED!');
    }
    setState(() => _playedPieces.add(piece));
    await BlocProvider.of<PuzzleBloc>(context).updatePuzzlePiece(
        piece.puzzlePiece.id,
        last: piece.puzzlePiece.last,
        isLocked: piece.puzzlePiece.isLocked);
    if (puzzle.numLocked == puzzle.maxPieces) {
      await BlocProvider.of<PuzzleBloc>(context).resetPuzzle(puzzle);
      print('GAME OVER!');
    }
  }

  Future<void> _droppedInLv(Piece piece, Offset topLeft) async {
    piece.puzzlePiece.last = RC();
    Utils.printListviewPieces(_lvPieces);
    int insertAt = // Insert piece into listview at current location
        Utils.findClosestLvElement(_lvPieces, isVerticalListview, topLeft);
// print('Inserting at $insertAt');
    setState(() {
      _lvPieces.insert(insertAt, piece);
    });

    await BlocProvider.of<PuzzleBloc>(context)
        .updatePuzzlePiece(piece.puzzlePiece.id, last: piece.puzzlePiece.last);
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

  bool _isDroppedInListView(Piece piece, Offset piecePos) {
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
