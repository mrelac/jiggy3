import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:jiggy3/models/album.dart';
import 'package:provider/provider.dart';

class AlbumBuilder extends StatelessWidget {
  final Album album;

  final VoidCallback onLongPress;
  final bool isEditing;

  const AlbumBuilder(
      {@required this.album, @required this.isEditing, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    ChooserBloc chooserBloc = Provider.of<ChooserBloc>(context);
    return StreamBuilder<List<Album>>(
        stream: BlocProvider.of<ChooserBloc>(context).albumsStream,
        builder: (context, snapshot) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: InkWell(
                child: Row(
                  children: [
                    if (album.isSelectable && isEditing)
                      Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Checkbox(
                              value: chooserBloc.shouldDeleteAlbum(album.id),
                              onChanged: (newValue) {
                                chooserBloc.toggleDeleteAlbum(album, newValue);
                              })),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(album.name, textScaleFactor: 2.5),
                    ),
                    if (album.isSelectable && isEditing)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: IconButton(
                          iconSize: 40,
                          icon: Icon(Icons.edit),
                          onPressed: () => chooserBloc.editAlbumName(album),
                        ),
                      )
                  ],
                ),
                onLongPress: onLongPress,
              ),
            ),
          );
        });
  }
}
