import 'dart:math';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/puzzle_piece.dart';

class PlayPage extends StatefulWidget {
  Puzzle puzzle;

  PlayPage(this.puzzle);

  _PlayPageState createState() => _PlayPageState();
}

// FIXME Don't know what the 'with WidgetsBindingObserver' is used to listen for.
// FIXME I thought it was to detect and handle device orientation changes, but
// FIXME I commented it out and the app still detects orientation changes!
class _PlayPageState
    extends State<PlayPage> /*with WidgetsBindingObserver*/ {
  final vlvPadding = EdgeInsets.only(bottom: 16.0, right: 16.0);
  final hlvPadding = EdgeInsets.only(right: 16.0, bottom: 16.0, top: 12);

// _elSize is the size of an element *with* padding
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
    // if (puzzle.playState != PlayState.inProgress) {
    if (_numPiecesOverlay == null) {
      _numPiecesOverlay = _createNumPiecesOverlay();
      Overlay.of(context).insert(_numPiecesOverlay);
    }
    // }

    await _loadPieces();

    setState(() {
      _image = puzzle.image.image;
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
      children: List.generate(widget.puzzle.piecesLoose.length, (index) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image(
            fit: BoxFit.fill,
            image: widget.puzzle.piecesLoose[index].image.image,
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
    if (widget.puzzle.isPortrait) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: _vertStrip(context),
        floatingActionButton: _buildFabMenu(context),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: _horizStrip(context),
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
  @deprecated
  int _maxBoxesPerRow(double boxWidth, EdgeInsets padding) {
    double bw = boxWidth + padding.left + padding.right;
    double verticalStripWidth =
        (widget.puzzle.isPortrait ?? true) ? _elSize.width : 0;
    double dw = deviceSize.width - verticalStripWidth;

    return (dw / bw).floor();
  }

  OverlayEntry _createNumPiecesOverlay() {
    // FIXME FIXME FIXME Center this overlay someday!
//    var position = _getPosition(_fabColourKey);
//    double height = 130.0;
//    double width = 550.0;
//    double left = position.dx - 23 - width;
//    if (left < 0) {
//      width += left;
//      left = 0;
//    }

    return OverlayEntry(
        builder: (context) => Positioned(
            key: _numPiecesKey,
            left: 0.0,
            top: 350,
            child: Material(
              color: Colors.grey[700],
              elevation: 4.0,
              child: Column(
                children: _getNumPiecesRows(),
              ),
            )));
  }

  // FIXME Moved to PuzzleSizeChooser
  @deprecated
  List<Widget> _getNumPiecesRows() {
    List<Widget> widgets = [];
    widgets.add(Container(
      child: Center(
        child: Text(
          'Puzzle Size',
          style: TextStyle(fontSize: 25, color: Colors.white70),
        ),
      ),
    ));

    int numBoxesPerRow = _maxBoxesPerRow(_sizeBoxWidth, _sizeBoxPadding);
    int start = 0;
    int end;
    while (start < sizeChoices.length) {
      end = min(start + numBoxesPerRow, sizeChoices.length);
      List<int> sub = sizeChoices.sublist(start, end);
      widgets.add(Row(children: _getSizeChoices(sub)));
      start += min(numBoxesPerRow, sizeChoices.length);
    }

    // This is the last row of widgets in the Puzzle Size chooser.
    widgets.add(Row(
      children: [
        ButtonTheme(
          child: RaisedButton(
            // onPressed: () async {
            //   print('play pressed');
            //   _closeNumPieces();
            //
            //
            //
            //
            //   File oldImageFile = new File(widget.puzzle.fileImage.file.path);
            //   if (_cropRequested.value) {
            //     puzzle = await _createPuzzleFromImage(
            //         puzzle, await ImageUtils.cropImageDialog(oldImageFile));
            //   } else {
            //     puzzle = await _createPuzzleFromImage(puzzle, oldImageFile);
            //   }
            //
            //   await _persist.deleteImage(widget.puzzle);
            //   await _persist.upsertPuzzle(puzzle);
            //
            //   List<PuzzlePiece> piecesLoose =
            //       await _splitImageIntoPieces(puzzle, _numPieces);
            //   puzzle.initialisePuzzleToPlay(piecesLoose);
            //
            //   setState(() {
            //     _image = puzzle.image.image;
            //     widget.puzzle = puzzle;
            //     // widget.notifyParent(puzzle);
            //   });
            // },
            textColor: Colors.white,
            color: Colors.grey[700],
            padding: const EdgeInsets.all(10.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.yellow,
                ),
                child: Center(
                    child: Row(
                  children: [
                    IconButton(
                      iconSize: 48.0,
                      icon: Icon(Icons.play_arrow),
                    ),
                  ],
                )),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Play', style: TextStyle(fontSize: 30)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: Text('Crop', style: TextStyle(fontSize: 20)),
        ),
        ValueListenableBuilder<bool>(
            valueListenable: _cropRequested,
            builder: (context, value, child) {
              return Checkbox(
                value: _cropRequested.value,
                onChanged: ((newValue) {
                  setState(() {
                    _cropRequested.value = newValue; // newValue;
                    print('Checkbox is now ${_cropRequested.value}');
                  });
                }),
              );
            }),
      ],
    ));

    return widgets;
  }

  final sizeChoices = <int>[
    1,
    2,
    3,
    4,
    5,
    8,
    12,
    50,
    77,
    96,
    140,
    200,
    234,
    336,
    400,
    432,
    512,
    756,
    1024
  ];
  final _sizeBoxWidth = 80.0;
  final _sizeBoxPadding = EdgeInsets.all(8.0);

  // FIXME Moved to PuzzleSizeChooser
  @deprecated
  List<Widget> _getSizeChoices(List<int> sizes) {
    var buttons = <ButtonTheme>[];

    for (int s in sizes) {
      buttons.add(
        ButtonTheme(
          minWidth: 30.0,
          child: RaisedButton(
            onPressed: () {
              _numPiecesOverlay.markNeedsBuild();
              setState(() {
                _numPieces = s;
                print('_numPieces now ${_numPieces.toString()}');
                Size ss = _getSize(_numPiecesKey);
                print('Puzzle Size Box: ${ss.width} x ${ss.height}');
              });
//              _closeNumPieces();
            },
            textColor: Colors.white70,
            color: Colors.grey[700],
            padding: _sizeBoxPadding,
            // const EdgeInsets.all(8.0),
            child: Container(
              width: _sizeBoxWidth,
              decoration: _puzzleSizeDecoration(s),
              child: Center(
                  child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text('${s.toString()}', style: TextStyle(fontSize: 25)),
              )),
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  // FIXME Moved to PuzzleSizeChooser
  @deprecated
  BoxDecoration _puzzleSizeDecoration(int size) {
    BoxDecoration bd;
    if (size == (_numPieces ?? 0)) {
      bd = BoxDecoration(
          border: Border.all(color: Colors.white70, width: 6.0),
          color: Colors.blueAccent);
    } else {
      bd = BoxDecoration(
        border: Border.all(color: Colors.yellow, width: 2.0),
        gradient: LinearGradient(
          colors: <Color>[
            Color(0xFF0D47A1),
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ],
        ),
      );
    }

    return bd;
  }

  // Replaced by Repository.createPuzzle()
  // @deprecated
  // Future<Puzzle> _createPuzzleFromImage(Puzzle puzzle, File imageFile) async {
  //   String nowDateStamp =
  //       DateFormat('yyyy-MM-dd_HH:mm:ss').format(DateTime.now());
  //   String name = widget.puzzle.name + "_" + nowDateStamp;
  //
  //   await ImageUtils.createImageFromFile(name, imageFile);
  //   String imageLocation = ImageUtils.createLocationFromName(name);
  //
  //   Puzzle p = Puzzle(
  //       id: puzzle.id,
  //       name: puzzle.name,
  //       thumb: imageFile.readAsBytesSync(),
  //       imageLocation: imageLocation,
  //       imageWidth: puzzle.imageWidth,
  //       imageHeight: puzzle.imageHeight,
  //       isEditing: globals.isEditing,
  //       isTicked: puzzle.isTicked,
  //       onEditTapped: puzzle.onEditTapped,
  //       onCheckboxTicked: puzzle.onCheckboxTicked,
  //       onChanged: puzzle.onChanged);
  //
  //   return p;
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

  Future<void> _initialisePuzzleForPlay() async {}

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

  Size _computeNumRowsAndCols(int numPieces) {
    double imageAspectRatio =
        widget.puzzle.imageWidth / widget.puzzle.imageHeight;
    // Compute number of cols: sqrt(numPieces * aspectRatio)
    int cols = sqrt(numPieces * imageAspectRatio).floor();

    // Compute number of rows: cols * 1 / aspectRatio
    int rows = (cols * 1 / imageAspectRatio).floor();

    print('Rows = $rows. cols = $cols');

    return Size(cols.toDouble(), rows.toDouble());
  }

  // FIXME This should go into a service
  @deprecated
  Future<List<PuzzlePiece>> _splitImageIntoPieces(
      Puzzle puzzle, int numPieces) async {
    var pieces = <PuzzlePiece>[];

//     Uint8List largeImageBytes =
//         await ImageUtils.getImageBytes(puzzle.image); // imageBytes
//     Size largeImageSize = await ImageUtils.getImageSize(puzzle.image);
//     imglib.Image imglibOriginalBytes =
//         imglib.decodeImage(largeImageBytes); // largeImage
//
//     double newHeight;
//     double newWidth;
//
//     if (ImageUtils.isPortrait(largeImageSize)) {
//       newHeight = max(deviceSize.height, deviceSize.width);
//       newWidth = min(deviceSize.height, deviceSize.width);
//     } else {
//       newHeight = min(deviceSize.height, deviceSize.width);
//       newWidth = max(deviceSize.height, deviceSize.width);
//     }
//
//     imglib.Image imglibSmallImage = imglib.copyResize(imglibOriginalBytes,
//         height: newHeight.toInt(), width: newWidth.toInt());
//     Image image2 = Image.memory(imglib.encodeJpg(imglibSmallImage));
//     Size smallImageSize = await ImageUtils.getImageSize(image2);
//     Uint8List smallImageBytes = await ImageUtils.getImageBytes(image2);
//     print(
//         'TEST: largeImage size = $largeImageSize. byteCount = ${largeImageBytes.length}');
//     print(
//         'TEST: smallImage size = $smallImageSize. byteCount = ${smallImageBytes.length}');
//
//     int x = 0, y = 0;
//     Size colsAndRows = _computeNumRowsAndCols(numPieces);
//     int numCols = colsAndRows.width.toInt();
//     int numRows = colsAndRows.height.toInt();
//     int width = (puzzle.image.width / numCols).floor();
//     int height = (puzzle.image.height / numRows).floor();
//     imglib.Image image = imglibSmallImage;
//     List<imglib.Image> parts = List<imglib.Image>();
//     for (int i = 0; i < numRows; i++) {
//       for (int j = 0; j < numCols; j++) {
// //print('x: $x, y: $y, width: $width, height: $height');
//         try {
//           parts.add(imglib.copyCrop(image, x, y, width, height));
//         } catch (e) {
//           break;
//         }
//         x += width;
//       }
//       x = 0;
//       y += height;
//     }
//
//     // convert image from image package to Image Widget to display
//     List<Image> output = List<Image>();
//     for (var img in parts) {
//       pieces.add(PuzzlePiece(image: Image.memory(imglib.encodeJpg(img))));
//     }
//
//     print('Loaded ${pieces.length} pieces. Width: $width, Height: $height');

    return pieces;
  }

  Future<void> _loadPieces() async {
    // load played pieces onto palette
    // load unplayed pieces into listview

    print('loading palette with locked and loose pieces');
  }
}
