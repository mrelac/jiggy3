import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/widgets/album_builder.dart';
import 'package:jiggy3/widgets/chooser_card.dart';
import 'package:provider/provider.dart';

/// The ChooserPage is where puzzles can be browsed and selected to play.
/// It is a StatefulWidget solely to take advantage of initState(), which
///   is executed only once.
class ChooserPage extends StatefulWidget {
  final String title;

  ChooserPage({Key key, this.title});

  _ChooserPageState createState() => _ChooserPageState();
}

class _ChooserPageState extends State<ChooserPage> {
  bool isEditing;

  @override
  void initState() {
    this.isEditing = false;
  }

  @override
  Widget build(BuildContext context) {
    ChooserBloc albumsBloc = Provider.of<ChooserBloc>(context);


    albumsBloc.applicationReset();



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

            return CircularProgressIndicator();
          }),
    );
  }

  /// Each album is expected to have its complete list of puzzles.
  List<Widget> buildAlbumsAndPuzzles(List<Album> albums) {
    final wlist = <Widget>[];

    for (Album album in albums) {
      wlist.addAll(buildAlbumAndPuzzles(album));
    }

    return wlist;
  }

  /// Each album is expected to have its complete list of puzzles.
  List<Widget> buildAlbumAndPuzzles(Album album) {
    ChooserBloc albumsBloc = Provider.of<ChooserBloc>(context);
    return [
      AlbumBuilder(
          isEditing: isEditing,
          album: album,
          onLongPressed: () {
            if ( ! isEditing)
              enableEditingMode(albumsBloc);
          }),
      Container(
        height: 164, // Must be specified or renderer fails
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: album.puzzles.length,
            itemBuilder: (BuildContext context, int index) {
              if (isEditing) {
                return Container(
                  key: Key('$index'),
                  color: Colors.orange[50],
                  child: ChooserCardEditing(
                    name: album.puzzles[index].name,
                    thumb: album.puzzles[index].thumb,
                    // isDeleteTicked: isDeleteTicked,
                    // onDeleteToggle: onDeleteToggle,
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
                    // onLongPress: onLongPress,
                    // onTap: onTap,
                  ),
                );
              }
            }),
      ),
    ];
  }

  void enableEditingMode(ChooserBloc albumsBloc) {
    isEditing = true;
    albumsBloc.clearAlbumsMarkedForDelete();
  }
}
