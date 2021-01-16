import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle_piece.dart';

// NOTE: EXECUTIVE DECISION: All puzzle images will be transformed to jpg,
//       regardless where they came from (e.g. network images - create jpg file), so ImageProvider is File

class Puzzle {
  int id;
  String name;
  Uint8List thumb;
  String imageLocation;
  Color imageColour = Color.fromRGBO(0xff, 0xff, 0xff, IMAGE_OPACITY_CLEAR);
  double imageOpacity = IMAGE_OPACITY_CLEAR;
  Image _image;

  // # of pieces locked to win game. -1 means 'Game not yet started'.
  int maxPieces = -1;
  final pieces = <PuzzlePiece>[];

  int get numLocked => pieces.where((p) => p.locked).toList().length;

  Image get image {
    return _image;
  }

  Future<void> loadImage() async {
    if (_image == null) {
      _image = await Repository.getPuzzleImage(imageLocation);
    }
}

  static const double IMAGE_OPACITY_CLEAR = 1.0;

  Puzzle(
      {this.id,
      @required this.name,
      @required this.thumb,
      @required this.imageLocation,
      imageColour,
      imageOpacity,
      maxPieces}) {
    if (imageColour != null) this.imageColour = imageColour;
    if (imageOpacity != null) this.imageOpacity = imageOpacity;
    if (maxPieces != null) this.maxPieces = maxPieces;
  }

  Puzzle.fromMap(Map json)
      : assert(json['name'] != null),
        assert(json['image_location'] != null),
        id = json['id'],
        name = json['name'],
        imageLocation = json['image_location'],
        imageOpacity = json['image_opacity'] {
    if (json['max_pieces'] != null) {
      this.maxPieces = json['max_pieces'];
    }
    if (json['thumb'] != null) {
      this.thumb = base64Decode(json['thumb']);
    }
    if (json['image_colour_r'] != null) {
      imageColour = Color.fromRGBO(
          json['image_colour_r'],
          json['image_colour_g'],
          json['image_colour_b'],
          json['image_opacity'] ?? IMAGE_OPACITY_CLEAR);
    }
  }

  Puzzle get from {
    return Puzzle(
        id: this.id,
        name: this.name,
        thumb: this.thumb,
        imageLocation: this.imageLocation,
        imageColour: this.imageColour,
        imageOpacity: this.imageOpacity,
        maxPieces: this.maxPieces);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Puzzle &&
          runtimeType == other.runtimeType &&
          name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'Puzzle{id: $id, name: $name, imageLocation: $imageLocation, '
        'maxPieces: $maxPieces}';
  }

  PlayState get playState {
    if (maxPieces == -1) {
      return PlayState.neverPlayed;
    } else if (numLocked == maxPieces) {
      return PlayState.completed;
    } else {
      return PlayState.inProgress;
    }
  }
}

enum PlayState { neverPlayed, inProgress, completed, notPlayable }
