import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';

class AppBarActions {
  static List<Widget> buildAppBaEditActions(ChooserBloc bloc) {
    final markedForDeleteCount = bloc.countItemsMarkedForDelete();
    return <Widget>[
      _generateDumpTables(bloc),
      if (markedForDeleteCount > 0) _generateDeleteSelected(bloc),
      _generateAddNewAlbum(bloc),
      _generateAddNewPuzzle(bloc),
      _generateApplicationReset(bloc),
    ];
  }

  static List<Widget> buildAppBarStandardActions(ChooserBloc bloc) {
    return <Widget>[
      _generateDumpTables(bloc),
      _generateAddNewAlbum(bloc),
      _generateAddNewPuzzle(bloc),
    ];
  }

  // PRIVATE METHODS

  static Widget _generateAddNewAlbum(ChooserBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: 'Create new album',
        child: IconButton(
          iconSize: 40,
          icon: Icon(Icons.add_to_photos),
          onPressed: () async => await bloc.createAlbum(),
        ),
      ),
    );
  }

  static Widget _generateAddNewPuzzle(ChooserBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: 'Pick new puzzle from gallery',
        child: IconButton(
          iconSize: 40,
          icon: Icon(Icons.add_photo_alternate),
          onPressed: () async {

            // FIXME After using FilePicker, check for image file extension and convert image to .jpg if needed.

            // FIXME ImagePicker doesn't handle .png correctly. Treats it like a jpg,
            // FIXME recommendation below is to use FilePicker instead.
            //       then fails because 'Start Of Image marker not found'
            // Check out: https://stackoverflow.com/questions/58998478/is-it-wrong-to-use-image-picker-in-flutter-for-png-file
            final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              await bloc.createAndInsertPuzzle(pickedFile.path);
            }
          },
        ),
      ),
    );
  }

  static Widget _generateDeleteSelected(ChooserBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: 'Deleting selected items',
        child: IconButton(
          iconSize: 40,
          icon: Icon(Icons.delete),
          onPressed: () async => await bloc.deleteSelectedItems(),
        ),
      ),
    );
  }

  static Widget _generateDumpTables(ChooserBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: 'Dump tables',
        child: IconButton(
          iconSize: 40,
          icon: Icon(Icons.category),
          onPressed: () async => await bloc.dumpTables(),
        ),
      ),
    );
  }

  static Widget _generateApplicationReset(ChooserBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: 'Drop database and reload from assets',
        child: IconButton(
          iconSize: 40,
          icon: Icon(Icons.refresh),
          onPressed: () async => await bloc.applicationReset(),
        ),
      ),
    );
  }
}
