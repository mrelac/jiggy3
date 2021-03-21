import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/blocs/puzzle_bloc.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/models/rc.dart';
import 'package:jiggy3/pages/play_page.dart';
import 'package:jiggy3/services/image_service.dart';

class NewPuzzleSetupPage extends StatefulWidget {
  final Puzzle puzzle;

  NewPuzzleSetupPage({@required this.puzzle});

  _NewPuzzleSetupPageState createState() => _NewPuzzleSetupPageState();
}

class _NewPuzzleSetupPageState extends State<NewPuzzleSetupPage> {
  File _croppedImageFile;
  RC _maxRc;
  Puzzle _returnedPuzzle;
  final _sizeBoxPadding = EdgeInsets.all(8.0);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Material(
        color: Colors.grey[700],
        elevation: 4.0,
        child: Column(children: [
          _puzzleName(),
          _puzzleSizeChooser,
          _puzzleSizes(),
          if (_maxRc != null) _crop(),
          if (_maxRc != null) _play()
        ]),
      ),
    );
  }

  Widget _puzzleName() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48.0, bottom: 0),
        child: Text(
          '${widget.puzzle.name}',
          style: TextStyle(fontSize: 50, color: Colors.white38),
        ),
      ),
    );
  }

  final Widget _puzzleSizeChooser = Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 64.0, bottom: 32),
      child: Text(
        'Please choose a puzzle size',
        style: TextStyle(fontSize: 30, color: Colors.white70),
      ),
    ),
  );

  Widget _puzzleSizes() {
    List<RC> maxPieces = _computeMaxPieces();
    return Center(
      child: GridView.extent(
        shrinkWrap: true,
        maxCrossAxisExtent: 100.0,
        childAspectRatio: 1.4,
        children: List.generate(
            maxPieces.length, (index) => _puzzleSizeButton(maxPieces[index])),
      ),
    );
  }

  Widget _puzzleSizeButton(RC puzzleSize) {
    return ButtonTheme(
      child: RaisedButton(
        onPressed: () => setState(() => _maxRc = puzzleSize),
        textColor: Colors.white70,
        color: Colors.grey[700],
        padding: _sizeBoxPadding,
        child: Container(
          decoration: _puzzleSizeDecoration(puzzleSize.row * puzzleSize.col),
          child: Center(
              child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Text('${(puzzleSize.row * puzzleSize.col).toString()}',
                style: TextStyle(fontSize: 25)),
          )),
        ),
      ),
    );
  }

  Widget _crop() {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: _textButton('Crop', Icons.crop, _onCropPressed));
  }

  Widget _play() {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: _textButton('Play', Icons.play_arrow, _onPlayPressed));
  }

  Future<void> _onCropPressed() async {
    _croppedImageFile =
        await ImageService.cropImageDialog(File(widget.puzzle.imageLocation));
    print('Cropped image file: $_croppedImageFile');
  }

  Future<void> _onPlayPressed() async {
    PuzzleBloc puzzleBloc = BlocProvider.of<PuzzleBloc>(context);
    Puzzle wp = widget.puzzle;
    _returnedPuzzle = wp.from;

    if (_croppedImageFile != null) {
      await puzzleBloc.deletePuzzleImage(wp.imageLocation);
      Puzzle p = await puzzleBloc.createPuzzle(wp.name, _croppedImageFile.path);
      _returnedPuzzle
        ..maxRc = _maxRc
        ..imageLocation = p.imageLocation
        ..thumb = p.thumb;
      await puzzleBloc.updatePuzzle(_returnedPuzzle.id,
          maxRc: _returnedPuzzle.maxRc,
          imageLocation: _returnedPuzzle.imageLocation,
          thumb: _returnedPuzzle.thumb);
    } else {
      _returnedPuzzle.maxRc = _maxRc;
      await puzzleBloc.updatePuzzle(_returnedPuzzle.id,
          maxRc: _returnedPuzzle.maxRc);
    }
    // FIXME Don't resize image here. Resize it in PlayPage where it needs
    // FIXME to be resized to account for the listview.
    await _returnedPuzzle.loadImage();
    // Image newImage = _fitImageForListview();
    // _returnedPuzzle.image = newImage;
    await puzzleBloc.splitImageIntoPieces(_returnedPuzzle, _maxRc);
    _onWillPop();
  }

  Image _fitImageForListview() {
    FileImage fi = _returnedPuzzle.image.image as FileImage;
    double width = _returnedPuzzle.image.width;
    double height = _returnedPuzzle.image.height;
    if (_returnedPuzzle.image.width > _returnedPuzzle.image.height) {
      width -= PlayPage.elWidth.toDouble();
    } else {
      height -= PlayPage.elHeight.toDouble();
    }
    Image newImage = Image.file(fi.file, width: width, height: height,
      fit: BoxFit.fill); // This stretches the image to fill image container
    return newImage;
  }

  bool get devIsPortrait =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  bool get devIsLandscape => !devIsPortrait;

  // The listview scrollbar always spans the short side of the device
  // (e.g. if dev is landscape, the sb is vertical; else it is horizontal)
  bool get isHorizontalListview => devIsPortrait;

  bool get isVerticalListview => !isHorizontalListview;

  Widget _textButton(String text, IconData iconData, Function onPressed) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            Text(text, style: TextStyle(fontSize: 40, color: Colors.white70)),
      ),
      RaisedButton(
        onPressed: onPressed,
        textColor: Colors.white,
        disabledColor: Colors.grey,
        color: Colors.grey[700],
        padding: const EdgeInsets.all(10.0),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.yellow,
          ),
          child: Center(
              child: IconButton(onPressed: null,
            iconSize: 48.0,
            icon: Icon(iconData, color: Colors.black),
          )),
        ),
      )
    ]);
  }

  BoxDecoration _puzzleSizeDecoration(int maxPuzzlePieces) {
    BoxDecoration bd;
    int selectedSize = _maxRc == null ? 0 : _maxRc.row * _maxRc.col;
    if (maxPuzzlePieces == selectedSize) {
      bd = BoxDecoration(
          border: Border.all(color: Colors.yellow, width: 4.0),
          color: Colors.blueAccent);
    } else {
      bd = BoxDecoration(
        border: Border.all(color: Colors.white70, width: 2.0),
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

  Future<bool> _onWillPop() {
    Navigator.pop(context, _returnedPuzzle);
    return Future.value(false);
  }

  /// Generates a list of row, col values that best fit the device coordinates
  /// in landscape. The row and column can be swapped later when needed if the
  /// image to be split is portrait, so don't worry about orientation here.
  List<RC> _computeMaxPieces() {
    return <RC>[
      RC(row: 3, col: 4), //   12
      RC(row: 6, col: 8), //   48
      RC(row: 9, col: 12), //  108
      RC(row: 12, col: 16), //  192
      RC(row: 15, col: 20), //  300
      RC(row: 18, col: 24), //  432
      RC(row: 24, col: 32), //  768
      RC(row: 27, col: 36), //  972
      RC(row: 30, col: 40), // 1200
      RC(row: 33, col: 44), // 1452
    ];
  }
}
