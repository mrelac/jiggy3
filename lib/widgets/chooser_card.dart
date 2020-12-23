import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:jiggy3/blocs/editing_name_bloc.dart';

const double IMAGE_HEIGHT_NOT_EDITING = 120.0;
const double IMAGE_HEIGHT_EDITING = 80.0;
const double CARD_WIDTH = 130.0;
const int MAX_NAME_LENGTH = 16;

class ChooserCard extends StatelessWidget {
  final String name;
  final Uint8List thumb;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const ChooserCard({
    Key key,
    @required this.name,
    @required this.thumb,
    this.onLongPress,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imagePadding = EdgeInsets.fromLTRB(2, 2, 2, 0);
    final labelPadding = EdgeInsets.fromLTRB(2, 0, 2, 0);

    return Card(
      color: Colors.grey[200],
      child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                color: Colors.grey[200],
                height: IMAGE_HEIGHT_NOT_EDITING,
                width: CARD_WIDTH,
                padding: imagePadding,
                child: IconButton(
                  iconSize: 250,
                  icon: Image.memory(thumb),
                ),
              ),
              Container(
                height: 28, // Keep text fixed size.
                padding: labelPadding,
                child: Center(
                    child: Text(name,
                        style: Theme.of(context).textTheme.headline6)),
              ),
            ],
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
          )),
    );
  }
}

typedef OnDeleteToggled = void Function(bool);

class ChooserCardEditing extends StatefulWidget {
  final Key key;
  final ChooserBloc bloc;
  final int id;
  final String name;
  final Uint8List thumb;
  final bool isDeleteTicked;
  final OnDeleteToggled onDeleteToggle;

  ChooserCardEditing({
    @required this.key,
    @required this.bloc,
    @required this.id,
    @required this.name,
    @required this.thumb,
    @required this.isDeleteTicked,
    @required this.onDeleteToggle,
  }) : super(key: key);

  _ChooserCardEditingState createState() => _ChooserCardEditingState();
}

class _ChooserCardEditingState extends State<ChooserCardEditing> {
  final _editingNameBloc = EditingNameBloc();
  final _editingNameController = TextEditingController();
  final FocusNode _editingNameFocusNode = FocusNode();

  Key get myEditingNameKey => Key('c-${widget.id.toString()}');
  Key _currentEditingNameKey;

  Key get currentEditingNameKey => _currentEditingNameKey;

  @override
  void initState() {
    super.initState();
    widget.bloc.editingNameStream.listen((key) {
      _currentEditingNameKey = key;
      // FIXME FIXME FIXME
      print('LISTENING: GOT KEY $key. my key: $myEditingNameKey');
    });
  }

  @override
  void dispose() {
    super.dispose();
    _editingNameBloc.dispose();
    _editingNameController.dispose();
    _editingNameFocusNode.dispose();
  }

  void cancelEditing() {
    _editingNameFocusNode.unfocus();
    widget.bloc.editingNameRequest(null);
  }

  @override
  Widget build(BuildContext context) {
    const imagePadding = EdgeInsets.fromLTRB(10, 0, 10, 0);
    const labelPadding = EdgeInsets.fromLTRB(10, 0, 10, 0);
    const double iconSize = 250.0;
    const labelHeight = 40.0;
    const checkboxHeight = 30.0;

    return Card(
      color: Colors.grey[200],
      child: Column(
        children: [
          Container(
            alignment: Alignment.topLeft,
            height: checkboxHeight,
            width: CARD_WIDTH,
            child: Checkbox(
              value: widget.isDeleteTicked ?? false,
            ),
          ),
          Container(
            color: Colors.grey[200],
            height: IMAGE_HEIGHT_EDITING,
            width: CARD_WIDTH,
            padding: imagePadding,
            child: IconButton(
              iconSize: iconSize,
              icon: Image.memory(widget.thumb),
            ),
          ),
          Row(
            children: [
              Container(
                height: labelHeight, // Keep text fixed size.
                padding: labelPadding,
                child: Center(
                  child: getPuzzleNameWidget(context),
                ),
              ),
              editingNameHandler(labelHeight),
            ],
          ),
        ],
      ),
    );
  }

  Widget editingNameHandler(double labelHeight) {
    widget.bloc.editingNameStream.listen((key) {
      _currentEditingNameKey = key;
      // FIXME FIXME FIXME
      print('LISTENING: GOT KEY $key. my key: $myEditingNameKey');
    });

    _editingNameBloc.excludedNames = widget.bloc.getPuzzleNames();

    if (widget.bloc.editingNameKey == myEditingNameKey) {
      // return cancel block
      return Container(
        height: labelHeight, // Keep text fixed size.
        padding: const EdgeInsets.only(left: 16.0),
        child: IconButton(
          iconSize: 30,
          icon: Icon(Icons.cancel),
          onPressed: () => cancelEditing(),
        ),
      );
    } else if (widget.bloc.editingNameKey == null) {
      // Return edit handler
      return Container(
        height: labelHeight, // Keep text fixed size.
        padding: const EdgeInsets.only(left: 16.0),
        child: IconButton(
          iconSize: 30,
          icon: Icon(Icons.edit),
          onPressed: () => widget.bloc.editingNameRequest(myEditingNameKey),
        ),
      );
    } else {
      // Return empty Container
      return Container();
    }
  }

  Widget getPuzzleNameWidget(BuildContext context) {
    if (currentEditingNameKey == myEditingNameKey) {
      _editingNameController.text = widget.name;
      _editingNameController.selection =
          TextSelection(baseOffset: 0, extentOffset: widget.name.length);

      return SizedBox(
        height: 200.0,
        width: 200.0,
        child: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: StreamBuilder<String>(
              stream: _editingNameBloc.textStream,
              builder: (context, textStream) {
                return TextField(
                  focusNode: _editingNameFocusNode,
                  controller: _editingNameController,
                  style: Theme.of(context).textTheme.headline6,
                  maxLength: MAX_NAME_LENGTH,
                  maxLengthEnforced: true,
                  onChanged: (String text) {
                    _editingNameBloc.update(
                        widget.name, _editingNameController.text);
                  },
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
                      widget.bloc.updatePuzzleName(widget.name, newName);
                      widget.bloc.editingNameRequest(null);
                    }
                  }),
                );
              }),
        ),
      );
    } else {
      return Text(widget.name, style: Theme.of(context).textTheme.headline6);
    }
  }
}
