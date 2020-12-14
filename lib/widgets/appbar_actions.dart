import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:provider/provider.dart';

class AppBarActions {

  static List<Widget> buildAppBaEditActions(ChooserBloc chooserBloc) {
    return <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: 'Dump tables',
          child: IconButton(
              iconSize: 40,
              icon: Icon(Icons.category),
              onPressed: () async => await chooserBloc.dumpTables(),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: 'Delete selected items',
          child: IconButton(
              iconSize: 40,
              icon: Icon(Icons.delete),
              onPressed: () {
                // _deleteSelected();
              }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: 'Create new album',
          child: IconButton(
              iconSize: 40,
              icon: Icon(Icons.add_photo_alternate),
              onPressed: () {
                // _addNewAlbum();
              }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: 'Pick new puzzle from gallery',
          child: IconButton(
              iconSize: 40,
              icon: Icon(Icons.add_photo_alternate),
              onPressed: () {
                print('Add a photo');
                // _addNewPuzzle();
              }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: 'Drop database and reload from assets',
          child: IconButton(
              iconSize: 40,
              icon: Icon(Icons.refresh),
              onPressed: () async => await chooserBloc.applicationReset(),
          ),
        ),
      ),
    ];
  }

  static List<Widget> buildAppBarStandardActions(ChooserBloc chooserBloc) {
    return <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: 'Dump tables',
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.category),
            onPressed: () async => await chooserBloc.dumpTables(),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: 'Delete selected items',
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.delete),
            // onPressed: () => _deleteSelected(),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: 'Create new album',
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.add_to_photos),
            // onPressed: () => _addNewAlbum(),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: 'Pick new puzzle from gallery',
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.add_photo_alternate),
            // onPressed: () => _addNewPuzzle()
          ),
        ),
      ),
    ];
  }
}