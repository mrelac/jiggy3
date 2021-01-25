
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/blocs/puzzle_bloc.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';
import 'package:jiggy3/widgets/palette_fab_menu.dart';
import 'package:jiggy3/widgets/piece.dart';

class PlayPage extends StatefulWidget {
  final Puzzle puzzle;

  PlayPage(this.puzzle);

  @override
  _PlayPageState createState() => _PlayPageState();
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

  final double _eW = 80.0; // Element width including padding
  final double _eH = 80.0; // Element height including padding
  final double _fW = 80.0; // fab width including padding
  final double _fH = 80.0; // fab height including padding

  double get eW => _eW;

  double get eH => _eH;

  double get fW => _fW;

  double get fH => _fH;

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
  final _lvPieces = <Widget>[]; // These are the dressed pieces in the listview
  final _playedPieces = <Widget>[]; // These are the played palette pieces
  ValueNotifier<double> _opacityFactor;

  void changeColor(Color color) {
    setState(() {
      _colourValue = color;
      widget.puzzle.imageColour = color;
      _updatePuzzle();
    });
  }

  @override
  void initState() {
    super.initState();

    PuzzleBloc puzzleBloc = BlocProvider.of<PuzzleBloc>(context);
    puzzleBloc.puzzlePiecesStream.listen((pieces) {
      final lvPieces = <Widget>[];
      final playedPieces = <Widget>[];
      pieces.forEach((puzzlePiece) {
        if (puzzlePiece.lastRow != null) {
          playedPieces.add(Piece(puzzlePiece));
        } else {
          lvPieces.add(Piece(puzzlePiece));
        }
      });
      setState(() {
        _lvPieces.addAll(lvPieces);
        _playedPieces.addAll(playedPieces);
      });
    });
    puzzleBloc.loadPuzzlePieces();

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

  @override
  Widget build(BuildContext context) {
    PuzzleBloc puzzleBloc = BlocProvider.of<PuzzleBloc>(context);
// fixme fixme fixme This file needs work.
    return StreamBuilder<List<PuzzlePiece>>(
        stream: puzzleBloc.puzzlePiecesStream,
        builder: (context, snapshot) {
          print('snapshot.connection state = ${snapshot.connectionState}');
          if ((snapshot.hasData) && (snapshot.data.isNotEmpty)) {
            print('Adding ${snapshot.data.length} pieces');
            // _lvPieces.addAll(_createPuzzlePieceForListview(snapshot.data));
          }
          // if (!snapshot.hasData) return BusyIndicator();
          return Scaffold(
            backgroundColor: Colors.grey[900],
            body: _buildBody(),
            floatingActionButton: _paletteFabMenu,
          );
        });
  }

  Widget _buildBody() {
    return Stack(
        children: <Widget>[]
          ..add(imgIsLandscape && devIsLandscape
              ? _landXland()
              : imgIsLandscape && devIsPortrait
                  ? _landXport()
                  : imgIsPortrait && devIsLandscape
                      ? _portXland()
                      : imgIsPortrait && devIsPortrait
                          ? _portXport()
                          : null)
          ..addAll(_playedPieces ?? <Widget>[]));
  }

  void onColourChanged(Color colour) {
    setState(() {
      _colourValue = colour;
      widget.puzzle.imageColour = colour;
    });
  }

  void onColourChangeEnd(Color colour) {
    _updatePuzzle();
  }

  void onImageOpacityChanged(double value) {
    setState(() {
      _opacityFactor.value = value;
      widget.puzzle.imageOpacity = value;
    });
  }

  void onImageOpacityChangEnd(double value) {
    print('Done changing slider. value: $value');
    _updatePuzzle();
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

  Widget _puzzleImage() {
    return DragTarget<Piece>(
        onWillAccept: (value) => true,
        onAcceptWithDetails: (DragTargetDetails<Piece> dtd) {
          print('onAccept: dtd = $dtd');
          Piece piece = dtd.data;

          // setState(() {
          //   print('left: ${dtd.offset.dx}, top: ${dtd.offset.dy}');
          //   _positionedPiece = Positioned(
          //     left: dtd.offset.dx,
          //     top: dtd.offset.dy,
          //     width: dtd.data.imageWidth,
          //     height: dtd.data.imageHeight,
          //     child: CustomPaint(
          //         foregroundPainter: PuzzlePiecePainter(
          //             piece.homeRow, piece.homeCol, piece.maxRow, piece.maxCol),
          //         child: piece.image),
          //   );
          // });
          // return _positionedPiece;
        },
        builder: (BuildContext context, List<Piece> pieces, List<dynamic> l) {
          return _imageBuilder();
        });
  }

  Widget _imageBuilder() => Container(
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
        fit: BoxFit.cover,
        image: _imgProvider,
      ));

  Widget _listView() {
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        color: _colourValue, // Background colour between pieces
        width: lW,
        height: lH,
        child: ListView.builder(
          cacheExtent: 1500,
          scrollDirection: devIsLandscape ? Axis.vertical : Axis.horizontal,
          itemCount: _lvPieces.length,
          itemBuilder: (context, index) {
            return Draggable<Piece>(
                data: _lvPieces[index],
                affinity: Axis.horizontal,
                feedback: _lvPieces[index],
                onDragCompleted: () {},
                child: _lvPieces[index]);
          },
        ),
      ),
    );
  }

  void _updatePuzzle() async {
    BlocProvider.of<PuzzleBloc>(context).updatePuzzle(widget.puzzle.id,
        imageColour: puzzle.imageColour, imageOpacity: puzzle.imageOpacity);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
