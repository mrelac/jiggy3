import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/widgets/album_builder.dart';
import 'package:jiggy3/widgets/busy_indicator.dart';
import 'package:jiggy3/widgets/chooser_card.dart';
import 'package:provider/provider.dart';

/// The ChooserPage is where puzzles can be browsed and selected to play.
/// It is a StatefulWidget solely to take advantage of initState(), which
///   is executed only once.
class ChooserPage extends StatefulWidget {
  final String title;
  bool applicationResetRequested;

  ChooserPage(
      {Key key, @required this.title, this.applicationResetRequested: false});

  _ChooserPageState createState() => _ChooserPageState();
}

class _ChooserPageState extends State<ChooserPage> {
  bool _isEditing;

  @override
  void initState() {
    super.initState();
    this._isEditing = false;
  }

  @override
  Widget build(BuildContext context) {
    ChooserBloc albumsBloc = Provider.of<ChooserBloc>(context);

    if (widget.applicationResetRequested) {
      ChooserBloc albumsBloc = Provider.of<ChooserBloc>(context);
      albumsBloc.applicationReset();
      widget.applicationResetRequested = false;
    }

    return Material(
      child: StreamBuilder<List<Album>>(
          stream: albumsBloc.albumsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Container(
                  child: CustomScrollView(
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(
                        buildAlbumsAndPuzzles(snapshot.data)),
                  )
                ],
              ));
            }

            return BusyIndicator();
          }),
    );
  }

  /// Each album is expected to have its complete list of puzzles.
  List<Widget> buildAlbumsAndPuzzles(List<Album> albums) {
    final wlist = <Widget>[];
    albums.forEach((album) => wlist.addAll(buildAlbumAndPuzzles(album)));
    return wlist;
  }

  /// Each album is expected to have its complete list of puzzles.
  List<Widget> buildAlbumAndPuzzles(Album album) {
    ChooserBloc chooserBloc = Provider.of<ChooserBloc>(context);
    return [
      AlbumBuilder(
          isEditing: _isEditing,
          album: album,
          onLongPress: () {
            if (!_isEditing) {
              _isEditing = true;
              chooserBloc.clearAlbumsMarkedForDelete();
            }
          }),
      Container(
        height: 164, // Must be specified or renderer fails
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: album.puzzles.length,
            itemBuilder: (BuildContext context, int index) {
              if (_isEditing) {
                return Container(
                  key: Key('$index'),
                  color: Colors.orange[50],
                  child: ChooserCardEditing(
                    name: album.puzzles[index].name,
                    thumb: album.puzzles[index].thumb,
                    isDeleteTicked:
                        chooserBloc.shouldDeletePuzzle(album.puzzles[index].id),
                    onDeleteToggle: (newValue) => chooserBloc
                        .toggleDeletePuzzle(album.puzzles[index].id, newValue),
                    // onEditTap: onEditTap,
                  ),
                );
              } else {
                return Container(
                  key: Key('$index'),
                  color: Colors.orange[50],
                  child: ChooserCard(
                      name: album.puzzles[index].name,
                      thumb: album.puzzles[index].thumb,
                      onLongPress: () {
                        if (!_isEditing) {
                          _isEditing = true;
                          chooserBloc.clearAlbumsMarkedForDelete();
                        }
                      }
                      // onTap: onTap,
                      ),
                );
              }
            }),
      ),
    ];
  }
}
