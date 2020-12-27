import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:jiggy3/blocs/editing_name_bloc.dart';
import 'package:jiggy3/models/album.dart';
import 'package:jiggy3/pages/chooser_page.dart';
import 'package:provider/provider.dart';

class AlbumBuilder extends StatefulWidget {
  final Album album;

  final VoidCallback onLongPress;
  final bool isInEditMode;

  const AlbumBuilder(
      {@required this.album, @required this.isInEditMode, this.onLongPress});

  _AlbumBuilderState createState() => _AlbumBuilderState();
}

class _AlbumBuilderState extends State<AlbumBuilder> {
  final _editingNameFocusNode = FocusNode();
  final _enBloc = EditingNameBloc();
  final _teController = TextEditingController();

  Key _currentEditingNameKey;

  Key get currentEditingNameKey => _currentEditingNameKey;

  Key get myEditingNameKey => Key('${widget.album.name}');

  @override
  void initState() {
    super.initState();
    _teController.addListener(_teListener);
  }

  void _teListener() {
    if (_teController.text.length > ChooserPage.MAX_NAME_LENGTH + 1) {
      String text =
          _teController.text.substring(0, ChooserPage.MAX_NAME_LENGTH + 1);
      _teController.value = _teController.value.copyWith(
        text: text,
        selection:
            TextSelection(baseOffset: text.length, extentOffset: text.length),
        composing: TextRange.empty,
      );
    }
    _enBloc.update(widget.album.name, _teController.text);
  }

  @override
  void dispose() {
    super.dispose();
    _enBloc.dispose();
    _teController.removeListener(_teListener);
    _teController.dispose();
    _editingNameFocusNode.dispose();
  }

  void _endEditing() {
    _editingNameFocusNode.unfocus();
    _teController.text = widget.album.name;
    Provider.of<ChooserBloc>(context, listen: false).editingNameRequest(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Builder(builder: (context) {
        if ((!widget.album.isSelectable) || (!widget.isInEditMode)) {
          return _generateText();
        } else if (editMode == EditMode.IsEditingNotSelf) {
          return _generateText();
        } else if (editMode == EditMode.NobodyEditing) {
          return Row(
            children: [
              _generateCheckBox(),
              _generateText(),
              _generateEditHandler(),
            ],
          );
        } else if (editMode == EditMode.IsEditingSelf) {
          return Row(children: [
            _generateTextField(),
            _generateCancelHandler(),
          ]);
        } else {
          throw Exception('Unexpected edit mode $editMode');
        }
      }),
    );
  }

  Widget _generateCancelHandler() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: IconButton(
        iconSize: 30,
        icon: Icon(Icons.cancel),
        onPressed: () => _endEditing(),
      ),
    );
  }

  Widget _generateCheckBox() {
    final ChooserBloc bloc = Provider.of<ChooserBloc>(context, listen: true);
    return Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Checkbox(
            value: bloc.isAlbumMarkedForDelete(widget.album.id),
            onChanged: (newValue) =>
                bloc.toggleDeleteAlbum(widget.album, newValue)));
  }

  Widget _generateEditHandler() {
    final ChooserBloc bloc = Provider.of<ChooserBloc>(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: IconButton(
        iconSize: 40,
        icon: Icon(Icons.edit),
        onPressed: () => bloc.editingNameRequest(myEditingNameKey),
      ),
    );
  }

  Padding _generateText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
          onLongPress: widget.onLongPress,
          child: Text(widget.album.name, textScaleFactor: 2.5)),
    );
  }

  Widget _generateTextField() {
    _teController.text = widget.album.name;
    _teController.selection =
        TextSelection(baseOffset: 0, extentOffset: widget.album.name.length);

    final ChooserBloc bloc = Provider.of<ChooserBloc>(context, listen: true);
    final mqTextScaleFactor =
        MediaQuery.of(context).copyWith(textScaleFactor: 1.7);

    return SizedBox(
      height: 100.0,
      width: 400.0,
      child: StreamBuilder<String>(
          stream: _enBloc.textStream,
          builder: (context, textStream) {
            _enBloc.excludedNames = bloc.getAlbumNames();
            return MediaQuery(
              data: mqTextScaleFactor,
              child: TextField(
                focusNode: _editingNameFocusNode,
                controller: _teController,
                style: Theme.of(context).textTheme.headline6,
                maxLength: ChooserPage.MAX_NAME_LENGTH,
                decoration: InputDecoration(
                  labelStyle: Theme.of(context).textTheme.headline6,
                  errorText: textStream.hasError ? textStream.error : null,
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                autocorrect: false,
                onSubmitted: ((newName) {
                  if (!textStream.hasError) {
                    bloc.updateAlbumName(widget.album.name, newName);
                    _endEditing();
                  }
                }),
              ),
            );
          }),
    );
  }

  EditMode get editMode {
    final ChooserBloc bloc = Provider.of<ChooserBloc>(context);
    if (bloc.editingNameKey == null) {
      return EditMode.NobodyEditing;
    } else if (bloc.editingNameKey == myEditingNameKey) {
      return EditMode.IsEditingSelf;
    } else {
      return EditMode.IsEditingNotSelf;
    }
  }
}

enum EditMode { NobodyEditing, IsEditingSelf, IsEditingNotSelf }
