import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

const double height = 120.0;

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

    return Material(
        child: Card(
      color: Colors.grey[200],
      child: Stack(
        children: [
          Card(
            color: Colors.grey[200],
            child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    new Container(
                      color: Colors.grey[200],
                      height: height,
                      width: 130,
                      padding: imagePadding,
                      child: IconButton(
                        iconSize: 250,
                        icon: Image.memory(thumb),
                      ),
                    ),
                    new Container(
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
          ),
        ],
      ),
    ));
  }
}

typedef OnDeleteToggled = void Function(bool);

class ChooserCardEditing extends StatelessWidget {
  final String name;
  final Uint8List thumb;
  final bool isDeleteTicked;
  final OnDeleteToggled onDeleteToggle;
  final VoidCallback onEditTap;

  const ChooserCardEditing({
    Key key,
    @required this.name,
    @required this.thumb,
    @required this.isDeleteTicked,
    @required this.onDeleteToggle,
    @required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imagePadding = EdgeInsets.fromLTRB(20, 20, 20, 0);
    final labelPadding = EdgeInsets.fromLTRB(20, 0, 20, 0);

    return Material(
        child: Card(
      color: Colors.grey[200],
      child: Stack(
        children: [
          Card(
            color: Colors.grey[200],
            child: InkWell(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                new Container(
                  color: Colors.grey[200],
                  height: height,
                  width: 130,
                  padding: imagePadding,
                  child: IconButton(
                    iconSize: 250,
                    icon: Image.memory(thumb),
                  ),
                ),
                new Container(
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
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Checkbox(
              value: isDeleteTicked ?? false,
              onChanged: onDeleteToggle,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              iconSize: 30,
              icon: Icon(Icons.edit),
              onPressed: onEditTap,
            ),
          ),
        ],
      ),
    ));
  }
}
