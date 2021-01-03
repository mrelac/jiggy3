import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/blocs/puzzle_bloc.dart';
import 'package:jiggy3/models/puzzle.dart';
import 'package:jiggy3/services/image_service.dart';
import 'package:jiggy3/services/puzzle_service.dart';

class NewPuzzleSetupPage extends StatefulWidget {
  final Puzzle puzzle;

  NewPuzzleSetupPage({@required this.puzzle});

  _NewPuzzleSetupPageState createState() => _NewPuzzleSetupPageState();
}

class _NewPuzzleSetupPageState extends State<NewPuzzleSetupPage> {
  final _maxPiecesChoices = <int>[
    1, 2, 3, 4, 5, 8, 12, 50, 77, 96, 140, 200, 234, 336, 400, 432, 512, 756, 1024,

    // 2, 6, 12, 48, 70, 88, 140, 200, 234, 336, 400, 432, 512, 756, 1024,
  ];
  File _croppedImageFile;
  int _maxPieces;
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
          _puzzleSizeChooser,
          _puzzleSizes(),
          _crop(),
          if (_maxPieces != null) _play()
        ]),
      ),
    );
  }

  final Widget _puzzleSizeChooser = Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 120.0, bottom: 32),
      child: Text(
        'Please choose a puzzle size',
        style: TextStyle(fontSize: 40, color: Colors.white70),
      ),
    ),
  );

  Widget _puzzleSizes() {
    return Center(
      child: GridView.extent(
        shrinkWrap: true,
        maxCrossAxisExtent: 100.0,
        childAspectRatio: 1.4,
        children: List.generate(_maxPiecesChoices.length,
            (index) => _puzzleSizeButton(_maxPiecesChoices[index])),
      ),
    );
  }

  Widget _puzzleSizeButton(int puzzleSize) {
    return ButtonTheme(
      child: RaisedButton(
        onPressed: () => setState(() => _maxPieces = puzzleSize),
        textColor: Colors.white70,
        color: Colors.grey[700],
        padding: _sizeBoxPadding,
        child: Container(
          decoration: _puzzleSizeDecoration(puzzleSize),
          child: Center(
              child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Text('${puzzleSize.toString()}',
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
        padding: const EdgeInsets.symmetric(vertical: 32.0),
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
    // Update _returned Puzzle as appropriate and save to database.
    _returnedPuzzle = wp.from;
    _returnedPuzzle.maxPieces = _maxPieces;
    if (_croppedImageFile != null) {
      Puzzle p = await puzzleBloc.createPuzzle(wp.name, _croppedImageFile.path);
      await puzzleBloc.deletePuzzleImage(wp.imageLocation);
      _returnedPuzzle
        ..imageLocation = p.imageLocation
        ..thumb = p.thumb
        ..imageWidth = p.imageWidth
        ..imageHeight = p.imageHeight;

      await puzzleBloc.updatePuzzle(_returnedPuzzle.id,
          imageLocation: _returnedPuzzle.imageLocation,
          thumb: _returnedPuzzle.thumb,
          imageWidth: _returnedPuzzle.imageWidth,
          imageHeight: _returnedPuzzle.imageHeight);
    }

    _returnedPuzzle.piecesLoose
      ..clear()
      ..addAll(await PuzzleService.splitImageIntoPieces(
          image: _returnedPuzzle.image,
          imageHeight: _returnedPuzzle.imageHeight,
          imageWidth: _returnedPuzzle.imageWidth,
          numPieces: _returnedPuzzle.maxPieces,
          deviceSize: MediaQuery.of(context).size));

    await puzzleBloc.updatePuzzle(_returnedPuzzle.id,
        maxPieces: _returnedPuzzle.piecesLoose.length);

    print('piecesLoose count: ${_returnedPuzzle.piecesLoose.length}');



    // FIXME TODO: INSERT piecesLoose INTO DATABASE!



    _onWillPop();
  }

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
              child: IconButton(
            iconSize: 48.0,
            icon: Icon(iconData, color: Colors.black),
          )),
        ),
      )
    ]);
  }

  BoxDecoration _puzzleSizeDecoration(int maxPuzzlePieces) {
    BoxDecoration bd;
    if (maxPuzzlePieces == (_maxPieces ?? 0)) {
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
}
