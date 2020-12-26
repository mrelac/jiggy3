import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:jiggy3/blocs/editing_name_bloc.dart';
import 'package:jiggy3/pages/chooser_page.dart';

const double IMAGE_HEIGHT_NOT_EDITING = 120.0;
const double IMAGE_HEIGHT_EDITING = 80.0;
const double CARD_WIDTH = 130.0;

class ChooserCard extends StatelessWidget {
  final String name;
  final Uint8List thumb;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const ChooserCard({
    @required this.name,
    @required this.thumb,
    this.onLongPress,
    this.onTap,
  });

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
  final String albumName;
  final ChooserBloc bloc;
  final int id;
  final String name;
  final Uint8List thumb;
  final bool isDeleteTicked;
  final OnDeleteToggled onDeleteToggle;

  ChooserCardEditing({
    @required this.albumName,
    @required this.bloc,
    @required this.id,
    @required this.name,
    @required this.thumb,
    @required this.isDeleteTicked,
    @required this.onDeleteToggle,
  });

  _ChooserCardEditingState createState() => _ChooserCardEditingState();
}

class _ChooserCardEditingState extends State<ChooserCardEditing> {
  final _editingNameFocusNode = FocusNode();
  final _enBloc = EditingNameBloc();
  final _teController = TextEditingController();

  Key _currentEditingNameKey;
  Key get currentEditingNameKey => _currentEditingNameKey;
  Key get myEditingNameKey =>
      Key('${widget.albumName}-${widget.id.toString()}');

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
    _enBloc.update(widget.name, _teController.text);
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
    _teController.text = widget.name;
    widget.bloc.editingNameRequest(null);
  }

  @override
  Widget build(BuildContext context) {
    const imagePadding = EdgeInsets.fromLTRB(10, 0, 10, 0);
    const labelPadding = EdgeInsets.fromLTRB(10, 0, 10, 0);
    const double iconSize = 250.0;
    const labelHeight = 40.0;
    const checkboxHeight = 30.0;

    _enBloc.excludedNames = widget.bloc.getPuzzleNames();

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
    });

    if (widget.bloc.editingNameKey == myEditingNameKey) {
      return Container(
        height: labelHeight, // Keep text fixed size.
        padding: const EdgeInsets.only(left: 16.0),
        child: IconButton(
          iconSize: 30,
          icon: Icon(Icons.cancel),
          onPressed: () {
            _endEditing();
          },
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
      _teController.text = widget.name;
      _teController.selection =
          TextSelection(baseOffset: 0, extentOffset: widget.name.length);
      return SizedBox(
        height: 200.0,
        width: 200.0,
        child: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: StreamBuilder<String>(
              stream: _enBloc.textStream,
              builder: (context, textStream) {
                return TextField(
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
                      widget.bloc.updatePuzzleName(widget.name, newName);
                      _endEditing();
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
