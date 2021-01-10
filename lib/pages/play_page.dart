
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/pages/chooser_page.dart';

class PlayPage extends StatefulWidget {
  static const PIECE_SIZE_NO_PADDING = 48.0;
  static const PIECE_SIZE_WITH_PADDING = 80.0;
  Puzzle puzzle;

  PlayPage(this.puzzle);

  _PlayPageState createState() => _PlayPageState();
}

// FIXME Don't know what the 'with WidgetsBindingObserver' is used to listen for.
// FIXME I thought it was to detect and handle device orientation changes, but
// FIXME I commented it out and the app still detects orientation changes!
class _PlayPageState extends State<PlayPage> /*with WidgetsBindingObserver*/ {
  final vlvPadding = EdgeInsets.only(bottom: 16.0, right: 16.0);
  final hlvPadding = EdgeInsets.only(right: 16.0, bottom: 16.0, top: 12);

// _elSize is the size of an element *with* padding
  // FIXME Replace _elSize with PIECE_SIZE_NO_PADDING and PIECE_SIZE_WITH_PADDING.
  final Size _elSize = Size(80.0, 80.0);


  Color _colourValue;
  bool _isReady = false;
  int _numPieces;
  Puzzle puzzle;
  ImageProvider _image;

  final GlobalKey<FabCircularMenuState> _fabKey = new GlobalKey();
  final GlobalKey _fabOpacityKey = new GlobalKey();
  final GlobalKey _fabColourKey = new GlobalKey();
  final GlobalKey _numPiecesKey = new GlobalKey();

  final GlobalKey _imageKey = new GlobalKey();

  OverlayEntry _colourOverlay;
  OverlayEntry _numPiecesOverlay;
  OverlayEntry _opacityOverlay;

  ValueNotifier<bool> _cropRequested;
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
    // This causes the named method to be called after the app layout is complete
    // WidgetsBinding.instance.addObserver(this);
    initialise();
  }

  // NOTES: This page is the play palette upon which an 'inProgress' puzzle is
  //        played.
  // Algorithm:
  // onInit():
  // - Set up PuzzleStream listener:
  //   - puzzleBloc.loadPuzzlPieces():
  //     - Load puzzle.piecesLocked and puzzle.piecesLoose
  //     - put updated puzzle in sink
  // - Set up PuzzlePieceStream listener:
  //   - onDrag:
  //     - Update puzzlePiece new row and column
  //     if new position is correct position:
  //     - update PuzzlePiece.locked field
  //     - move puzzle.puzzlePiece from loose to locked list
  //     - Update database: puzzlePiece.row, .col, puzzle.loose, puzzle.locked
  //
  // build():
  // - paintImage() (e.g. update palette with image)
  // - If hasData:
  //   - return Widget play():
  //     - paintImage(), loadLocked(), loadLoose(), loadFab()
  //

  Size get deviceSize => MediaQuery.of(context).size;

  bool isPortrait() =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  Future<void> initialise() async {
    await _noOp(); // Required for .insert(_numPiecesOverlay) to work
    puzzle = widget.puzzle;
    _opacityFactor = new ValueNotifier<double>(puzzle.imageOpacity);
    _colourValue = puzzle.imageColour;
    _cropRequested =
        new ValueNotifier<bool>(false); // FIXME: Moved to PuzzleSizeChooser
    Image image = await puzzle.image;
    setState(() {
      _image = image.image;
      _isReady = true;
    });
  }

  // Needs to be called before _numPiecesOverlay can be .inserted
  Future<void> _noOp() async {}

  // Listens for device orientation changes
  // @override
  // void didChangeMetrics() {
  //   double width = WidgetsBinding.instance.window.physicalSize.width;
  //   double height = WidgetsBinding.instance.window.physicalSize.height;
  //
  //   String o = width < height ? "portrait" : "landscape";
  //   print('orientation is $o');
  //   if (_numPiecesOverlay != null) {
  //     _numPiecesOverlay.markNeedsBuild();
  //   }
  // } //  @override
  Widget _horizStrip(BuildContext context) {
    final lvWidth = MediaQuery.of(context).size.bottomRight(Offset.zero).dx -
        _elSize.width -
        hlvPadding.horizontal;
    final lvHeight = _elSize.height - hlvPadding.vertical;
    final imgWidth = MediaQuery.of(context).size.bottomRight(Offset.zero).dx;
    var imgHeight = MediaQuery.of(context).size.bottomRight(Offset.zero).dy -
        lvHeight -
        hlvPadding.vertical;

//    print('_horizStrip: img:  ($imgWidth, $imgHeight)');
//    print('_horizStrip: lv:   ($lvWidth, $lvHeight)');
//    print('_horizStrip: menu: ($menuWidth, $menuHeight)');

    return Center(
      child: Column(children: [
        _imgContainer(context, imgWidth, imgHeight),
        Row(
          children: [
            _listviewContainer(
                context, lvWidth, lvHeight, hlvPadding, Axis.horizontal),
          ],
        ),
      ]),
    );
  }

  Widget _vertStrip(BuildContext context) {
    final lvWidth = _elSize.width - vlvPadding.horizontal;
    final lvHeight = MediaQuery.of(context).size.bottomRight(Offset.zero).dy -
        _elSize.height -
        vlvPadding.vertical;
    final imgHeight = MediaQuery.of(context).size.bottomRight(Offset.zero).dy;
    final imgWidth = MediaQuery.of(context).size.bottomRight(Offset.zero).dx -
        lvWidth -
        vlvPadding.horizontal;

//    print('_vertStrip: img:  ($imgWidth, $imgHeight)');
//    print('_vertStrip: lv:   ($lvWidth, $lvHeight)');
//    print('_vertStrip: menu: ($menuWidth, $menuHeight)');

    return Row(children: [
      _imgContainer(context, imgWidth, imgHeight),
      Column(
        children: [
          _listviewContainer(
              context, lvWidth, lvHeight, vlvPadding, Axis.vertical),
        ],
      ),
    ]);
  }

  Widget _listviewContainer(BuildContext context, double lvWidth,
      double lvHeight, EdgeInsets lvPadding, Axis axis) {
    return Padding(
      padding: lvPadding,
      child: Container(
        color: _colourValue,
        width: lvWidth,
        height: lvHeight,
        child: _listView(context, axis),
      ),
    );
  }

  Widget _listView(BuildContext context, Axis axis) {
    return ListView(
      scrollDirection: axis,
      children: List.generate(widget.puzzle.pieces.length, (index) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image(
            fit: BoxFit.fill,
            image: widget.puzzle.pieces[index].image.image,
          ),
        );
      }),
    );
  }

  Widget _imgContainer(
      BuildContext context, double imgWidth, double imgHeight) {
    return Container(
      alignment: Alignment.topLeft,
      child: Image(
        key: _imageKey,
        // FIXME probably not needed
        color: Color.fromRGBO(
            widget.puzzle.imageColour.red,
            widget.puzzle.imageColour.green,
            widget.puzzle.imageColour.blue,
            _opacityFactor.value),
        colorBlendMode: BlendMode.modulate,
        width: imgWidth,
        height: imgHeight,
        image: _image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Center(
        child: Container(
          height: 180.0,
          width: 180.0,
          child: CircularProgressIndicator(),
        ),
      );
    }

    SystemChrome.setEnabledSystemUIOverlays([]); // Hide top status bar
    // The pieces strip is always on the device short side regardless of puzzle orientation
    if (ChooserPage.deviceSize.width < ChooserPage.deviceSize.height) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: _horizStrip(context),
        floatingActionButton: _buildFabMenu(context),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: _vertStrip(context),
        floatingActionButton: _buildFabMenu(context),
      );
    }
  }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(this);
    _closeOverlays();
    super.dispose();
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

  // FIXME Moved to PuzzleSizeChooser
  // @deprecated
  // int _maxBoxesPerRow(double boxWidth, EdgeInsets padding) {
  //   double bw = boxWidth + padding.left + padding.right;
  //   double verticalStripWidth =
  //       (widget.puzzle.isPortrait ?? true) ? _elSize.width : 0;
  //   double dw = deviceSize.width - verticalStripWidth;
  //
  //   return (dw / bw).floor();
  // }

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
      //          ),
      //        ),
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
}
