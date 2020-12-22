import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:provider/provider.dart';

class AppBarActions {
  static List<Widget> buildAppBaEditActions(ChooserBloc chooserBloc) {
    final markedForDeleteCount = chooserBloc.countItemsMarkedForDelete();
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
      if (markedForDeleteCount > 0)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Tooltip(
            message:
                'Delete $markedForDeleteCount selected items',
            child: IconButton(
              iconSize: 40,
              icon: Icon(Icons.delete),
              onPressed: () async => await chooserBloc.deleteSelectedItems(),
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
              onPressed: () {
                // TODO - Create new album
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
                // TODO - Add a photo
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
          message: 'Create new album',
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.add_to_photos),
            // TODO - Create new album
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
            // TODO - Create new album
            // onPressed: () => _addNewPuzzle()
          ),
        ),
      ),
    ];
  }
}
