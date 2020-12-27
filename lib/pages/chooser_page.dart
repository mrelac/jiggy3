import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/widgets/album_builder.dart';
import 'package:jiggy3/widgets/appbar_actions.dart';
import 'package:jiggy3/widgets/busy_indicator.dart';
import 'package:jiggy3/widgets/chooser_card.dart';
import 'package:provider/provider.dart';

const ARG_RESET =
    String.fromEnvironment('applicationReset', defaultValue: 'false');

// TODO - Bugs
// - Implement DeleteItems
// - Implement AddAlbum
// - Implement AddPuzzle
// - Implement move puzzle
// - Figure out how to get keyboard to NOT cover editing textfield
// - Append date to puzzleImage file, as the puzzle name can change
//

/// The ChooserPage is where puzzles can be browsed and selected to play.
/// It is a StatefulWidget solely to take advantage of initState(), which
///   is executed only once.
class ChooserPage extends StatefulWidget {
  final String title;
  static const int MAX_NAME_LENGTH = 16;

  ChooserPage({@required this.title});

  _ChooserPageState createState() => _ChooserPageState();
}

class _ChooserPageState extends State<ChooserPage> {
  AppBar _appBar;
  AppBar _appBarStandard;
  AppBar _appBarEdit;

  @override
  void initState() {
    super.initState();

    final bool applicationResetRequested = ARG_RESET.toLowerCase() == 'true';
    if (applicationResetRequested) {
      BlocProvider.of<ChooserBloc>(context).applicationReset();
    }
    _appBarEdit = _buildAppBarEditActions();
    _appBarStandard = _buildAppBarStandardActions();
    _appBar = _appBarStandard;
    BlocProvider.of<ChooserBloc>(context).setEditMode(false);
    BlocProvider.of<ChooserBloc>(context, listen: false).editModeStream.listen(
        (isInEditMode) => setState(
            () => _appBar = isInEditMode ? _appBarEdit : _appBarStandard));
  }

  bool get isInEditMode {
    return BlocProvider.of<ChooserBloc>(context, listen: false).isInEditMode;
  }

  @override
  Widget build(BuildContext context) {
    ChooserBloc chooserBloc = Provider.of<ChooserBloc>(context);
    SystemChrome.setEnabledSystemUIOverlays([]); // Hide status bars and such

    return Scaffold(
      appBar: _appBar,
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
              return BusyIndicator(chooserBloc.progress);
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
          isInEditMode: isInEditMode, album: album, onLongPress: _onLongPress),
      Container(
        height: 164, // Must be specified or renderer fails
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: album.puzzles.length,
            itemBuilder: (BuildContext context, int index) {
              if (isInEditMode) {
                return Container(
                  key: Key('$index'),
                  color: Colors.orange[50],
                  child: ChooserCardEditing(
                    id: album.puzzles[index].id,
                    albumName: album.name,
                    name: album.puzzles[index].name,
                    thumb: album.puzzles[index].thumb,
                  ),
                );
              } else {
                return Container(
                  key: Key('$index'),
                  color: Colors.orange[50],
                  child: ChooserCard(
                    name: album.puzzles[index].name,
                    thumb: album.puzzles[index].thumb,
                    onLongPress: _onLongPress,
                    onTap: () =>
                        print('puzzle ${album.puzzles[index].name} tapped'),
                  ),
                );
              }
            }),
      ),
    ];
  }

  void _onLongPress() {
    if (!isInEditMode) {
      Provider.of<ChooserBloc>(context, listen: false).setEditMode(true);
    }
  }

  Widget _buildAppBarEditActions() {
    return AppBar(
      leading: IconButton(
        iconSize: 40.0,
        icon: Icon(Icons.cancel),
        onPressed: () => BlocProvider.of<ChooserBloc>(context, listen: false)
            .setEditMode(false),
      ),
      backgroundColor: Colors.green[100],
      actions: AppBarActions.buildAppBaEditActions(
          BlocProvider.of<ChooserBloc>(context, listen: false)),
    );
  }

  Widget _buildAppBarStandardActions() {
    return AppBar(
      centerTitle: true,
      title: Text("Jiggy!"),
      backgroundColor: Colors.amber[100],
      elevation: 0.0,
      actions: AppBarActions.buildAppBarStandardActions(
          BlocProvider.of<ChooserBloc>(context, listen: false)),
    );
  }
}
