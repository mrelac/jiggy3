import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jiggy3/blocs/puzzle_bloc.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';

class PlayPage extends StatefulWidget {
  Puzzle puzzle;

  PlayPage(this.puzzle);

  _PlayPageState createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  Size _imgSize;

  Size get imgSize => _imgSize;

  bool get imgIsPortrait => imgSize.width < imgSize.height;

  bool get imgIsLandscape => !imgIsPortrait;

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

  final GlobalKey<FabCircularMenuState> _fabKey = new GlobalKey();
  final GlobalKey _fabOpacityKey = new GlobalKey();
  final GlobalKey _fabColourKey = new GlobalKey();

  OverlayEntry _colourOverlay;
  OverlayEntry _numPiecesOverlay;
  OverlayEntry _opacityOverlay;

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

    puzzle = widget.puzzle;
    _opacityFactor = new ValueNotifier<double>(puzzle.imageOpacity);
    _imgSize = Size(widget.puzzle.image.width, widget.puzzle.image.height);
    _imgProvider = widget.puzzle.image.image;
    _colourValue = puzzle.imageColour;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to puzzlePieces and fill listview as they are available.

    PuzzleBloc puzzleBloc = BlocProvider.of<PuzzleBloc>(context);
    puzzleBloc.puzzlesStream.listen((puzzle) async {
      await puzzle.loadImage();
    });

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: _buildBody(),
      floatingActionButton: _buildFabMenu(context),
    );
  }

  Widget _buildBody() {
    return imgIsLandscape && devIsLandscape
        ? _landXland()
        : imgIsLandscape && devIsPortrait
            ? _landXport()
            : imgIsPortrait && devIsLandscape
                ? _portXland()
                : imgIsPortrait && devIsPortrait
                    ? _portXport()
                    : null;
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
        fit: BoxFit.cover,
        image: _imgProvider,
      ),
    );
  }

  Widget _listView() {
    PuzzleBloc puzzleBloc = BlocProvider.of<PuzzleBloc>(context);
    Stream<List<PuzzlePiece>> piecesStream = puzzleBloc.puzzlePiecesStream;
    piecesStream.listen((pieces) {
      pieces.forEach((piece) => _lvPieces.add(Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.memory(piece.imageBytes, fit: BoxFit.fill),
          )));
    });
    return StreamBuilder<Object>(
        stream: puzzleBloc.puzzlePiecesStream,
        initialData: [],
        builder: (context, snapshot) {
          return Padding(
            padding: EdgeInsets.zero,
            child: Container(
              color: _colourValue,
              width: lW,
              height: lH,
              child: ListView(
                scrollDirection:
                    devIsLandscape ? Axis.vertical : Axis.horizontal,
                children: _lvPieces,
              ),
            ),
          );
        });
  }

  // FIXME Move this to new widget file PaletteFabMenu.
  @deprecated
  OverlayEntry _createOpacityOverlay() {
    var size = _getSize(_fabOpacityKey);
    if (size == null) {
      return null;
    }
    var position = _getPosition(_fabOpacityKey);
    double width = 550.0;
    double left = position.dx - 23 - width;
    if (left < 0) {
      width += left;
      left = 0;
    }
    return OverlayEntry(
        builder: (overlayContext) => Positioned(
            left: left,
            width: width,
            top: position.dy + 10,
            height: size.height - 20,
            child: Material(
              elevation: 4.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text('Opacity'),
                  ),
                  _createOpacitySlider(overlayContext),
                ],
              ),
            )));
  }

  // FIXME Move this to new widget file PaletteFabMenu.
  @deprecated
  Widget _createOpacitySlider(BuildContext context) {
    return ValueListenableBuilder<double>(
        valueListenable: _opacityFactor,
        builder: (context, value, child) {
          return Slider(
            value: _opacityFactor.value,
            min: 0.0,
            max: 1.0,
            onChanged: (double value) {
              setState(() {
                _opacityFactor.value = value;
                widget.puzzle.imageOpacity = value;
              });
            },
            onChangeEnd: (double value) {
              print('Done changing slider. value: $value');
              _updatePuzzle();
            },
          );
        });
  }

  // FIXME FIXME FIXME
  void _updatePuzzle() async {
    print('FIXME: PERSIST ME!');
    // await _persist.upsertPuzzle(widget.puzzle);
  }

  // FIXME Move this to new widget file PaletteFabMenu.
  @deprecated
  OverlayEntry _createColourOverlay() {
    var size = _getSize(_fabColourKey);
    if (size == null) {
      return null;
    }
    var position = _getPosition(_fabColourKey);
    double height = 130.0;
    double width = 550.0;
    double left = position.dx - 23 - width;
    if (left < 0) {
      width += left;
      left = 0;
    }

    return OverlayEntry(
        builder: (context) => Positioned(
            left: left,
            width: width,
            height: height,
            top: position.dy - 58,
            child: Material(
              elevation: 4.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: ColorPicker(
                      pickerColor: _colourValue,
                      onColorChanged: changeColor,
                      colorPickerWidth: width,
                      pickerAreaHeightPercent: 0.1,
                      enableAlpha: false,
                      displayThumbColor: false,
                      showLabel: false,
                      paletteType: PaletteType.hsv,
                      pickerAreaBorderRadius: const BorderRadius.only(
                        topLeft: const Radius.circular(2.0),
                        topRight: const Radius.circular(2.0),
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }

  Offset _getPosition(GlobalKey key) {
    final RenderBox renderBox = key.currentContext.findRenderObject();
    return renderBox.localToGlobal(Offset.zero);
  }

  Size _getSize(GlobalKey key) {
    final RenderBox renderBox = key.currentContext?.findRenderObject();
    return renderBox?.size;
  }

  // FIXME Move this to new widget file PaletteFabMenu.
  @deprecated
  Widget _buildFabMenu(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Builder(
      builder: (context) => FabCircularMenu(
        key: _fabKey,
        // Cannot be `Alignment.center`
        alignment: Alignment.bottomRight,
        ringColor: Colors.white.withAlpha(25),
        ringDiameter: 600.0,
        ringWidth: 100.0,
        fabSize: 60.0,
        fabElevation: 8.0,

        // Also can use specific color based on whether
        // the menu is open or not:
        // fabOpenColor: Colors.white
        // fabCloseColor: Colors.white
        // These properties take precedence over fabColor
        fabColor: Colors.indigo,
        fabOpenIcon: Icon(Icons.menu, color: primaryColor),
        fabCloseIcon: Icon(Icons.close, color: primaryColor),
        fabMargin: const EdgeInsets.all(8.0),
        animationDuration: const Duration(milliseconds: 800),
        animationCurve: Curves.easeInOutCirc,
        onDisplayChange: (isOpen) {
          print('The menu is ${isOpen ? "open" : "closed"}');
          if (!isOpen) {
            _closeSiders();
          }
        },
        children: <Widget>[
          Container(
            child: Tooltip(
              message: 'Opacity',
              child: RawMaterialButton(
                key: _fabOpacityKey,
                onPressed: () {
                  if (_opacityOverlay == null) {
                    _opacityOverlay = _createOpacityOverlay();
                    Overlay.of(context).insert(_opacityOverlay);
                  } else {
                    _opacityOverlay.remove();
                    _opacityOverlay = null;
                  }
//              fabKey.currentState.close();
                },
                shape: CircleBorder(),
                splashColor: Colors.red,
                fillColor: Colors.blueAccent,
                padding: const EdgeInsets.all(24.0),
                child: Icon(Icons.opacity, color: Colors.white, size: 30.0),
              ),
            ),
          ),
          Container(
            child: Tooltip(
              message: 'Background colour',
              child: RawMaterialButton(
                key: _fabColourKey,
                onPressed: () {
                  print("Choose background colour");
                  if (_colourOverlay == null) {
                    _colourOverlay = _createColourOverlay();
                    Overlay.of(context).insert(_colourOverlay);
                  } else {
                    _colourOverlay.remove();
                    _colourOverlay = null;
                  }
                },
                shape: CircleBorder(),
                splashColor: Colors.red,
                fillColor: Colors.green,
                padding: const EdgeInsets.all(24.0),
                child: Icon(Icons.colorize, color: Colors.white, size: 30.0),
              ),
            ),
          ),
          Container(
            child: Tooltip(
              message: 'Edges',
              child: RawMaterialButton(
                onPressed: () {
                  print("Toggle show edge pieces");
                  _fabKey.currentState.close();
                },
                shape: CircleBorder(),
                splashColor: Colors.red,
                fillColor: Colors.orange,
                padding: const EdgeInsets.all(24.0),
                child: Icon(Icons.extension, color: Colors.white, size: 30.0),
              ),
            ),
          ),
          Container(
            child: Tooltip(
              message: 'Preview',
              child: RawMaterialButton(
                onPressed: () {
                  print("Toggle show preview");
                },
                shape: CircleBorder(),
                splashColor: Colors.red,
                fillColor: Colors.yellowAccent,
                padding: const EdgeInsets.all(24.0),
                child: Icon(Icons.all_out, color: Colors.black, size: 30.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _closeNumPieces() {
    if (_numPiecesOverlay != null) {
      _numPiecesOverlay.remove();
      _numPiecesOverlay = null;
    }
  }

  _closeSiders() {
    if (_opacityOverlay != null) {
      _opacityOverlay.remove();
      _opacityOverlay = null;
    }
    if (_colourOverlay != null) {
      _colourOverlay.remove();
      _colourOverlay = null;
    }
  }

  _closeOverlays() {
    _closeNumPieces();
    _closeSiders();
  }

  @override
  void dispose() {
    _closeOverlays();
    super.dispose();
  }
}
