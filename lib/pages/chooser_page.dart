import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/widgets/album_builder.dart';
import 'package:jiggy3/widgets/appbar_actions.dart';
import 'package:jiggy3/widgets/busy_indicator.dart';
import 'package:jiggy3/widgets/chooser_card.dart';
import 'package:provider/provider.dart';

/// The ChooserPage is where puzzles can be browsed and selected to play.
/// It is a StatefulWidget solely to take advantage of initState(), which
///   is executed only once.
class ChooserPage extends StatefulWidget {
  final String title;
  final bool applicationResetRequested;

  ChooserPage(
      {Key key, @required this.title, this.applicationResetRequested: false});

  _ChooserPageState createState() => _ChooserPageState();
}

class _ChooserPageState extends State<ChooserPage> {
  bool _isEditing;

  @override
  void initState() {
    super.initState();
    if (widget.applicationResetRequested) {
      BlocProvider.of<ChooserBloc>(context).applicationReset();
    }

    this._isEditing = false;
  }

  @override
  Widget build(BuildContext context) {
    ChooserBloc chooserBloc = Provider.of<ChooserBloc>(context);
    SystemChrome.setEnabledSystemUIOverlays([]); // Hide status bars and such

    return Scaffold(
      appBar: _isEditing
          ? _buildAppBarEditActions()
          : _buildAppBarStandardActions(),
      body: Material(
        child: StreamBuilder<List<Album>>(
            stream: chooserBloc.albumsStream,
            builder: (context, snapshot) {
              if ((snapshot.hasData) &&
                  (!chooserBloc.isApplicationResetting())) {
                return Container(
                    child: CustomScrollView(
                  slivers: <Widget>[
                    SliverList(
                      delegate: SliverChildListDelegate(
                          _buildAlbumsAndPuzzles(snapshot.data)),
                    )
                  ],
                ));
              }
              return BusyIndicator();
            }),
      ),
    );
  }

  // PRIVATE METHODS

  /// Each album is expected to have its complete list of puzzles.
  List<Widget> _buildAlbumsAndPuzzles(List<Album> albums) {
    final wlist = <Widget>[];
    albums.forEach((album) => wlist.addAll(_buildAlbumAndPuzzles(album)));
    return wlist;
  }

  /// Each album is expected to have its complete list of puzzles.
  List<Widget> _buildAlbumAndPuzzles(Album album) {
    ChooserBloc chooserBloc = Provider.of<ChooserBloc>(context);
    return [
      AlbumBuilder(
          isEditing: _isEditing,
          album: album,
          onLongPress: () {
            if (!_isEditing) {
              _isEditing = !_isEditing;
              chooserBloc.clearItemsMarkedForDelete();
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
                        _isEditing = !_isEditing;
                        chooserBloc.clearItemsMarkedForDelete();
                      }
                    },
                    onTap: () =>
                        print('puzzle ${album.puzzles[index].name} tapped'),
                  ),
                );
              }
            }),
      ),
    ];
  }

  Widget _buildAppBarEditActions() {
    return AppBar(
      leading: IconButton(
        iconSize: 40.0,
        icon: Icon(Icons.cancel),
        // onPressed: () => _onEditingCanceled(),
      ),
      backgroundColor: Colors.green[100],
      actions: AppBarActions.buildAppBaEditActions(),
    );
  }

  Widget _buildAppBarStandardActions() {
    return AppBar(
      centerTitle: true,
      title: Text("Jiggy!"),
      backgroundColor: Colors.amber[100],
      elevation: 0.0,
      actions: AppBarActions.buildAppBarStandardActions(),
    );
  }
}
