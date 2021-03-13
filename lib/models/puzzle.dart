import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/rc.dart';

// NOTE: EXECUTIVE DECISION: All puzzle images will be transformed to jpg,
//       regardless where they came from (e.g. network images - create jpg file), so ImageProvider is File

class Puzzle {
  int id;
  String name;
  Uint8List thumb;
  String imageLocation;
  Color imageColour = Color.fromRGBO(0xff, 0xff, 0xff, IMAGE_OPACITY_DIM);
  double imageOpacity = IMAGE_OPACITY_DIM;
  Image _image;
  int numLocked = 0;
  RC maxRc;

  // # of pieces locked to win game. > 0 means 'Game in progress'.
  int get maxPieces => maxRc == null ? 0 : maxRc.row * maxRc.col;

  int previousMaxPieces;

  Image get image {
    return _image;
  }

  set image(Image value) {
    _image = value;
  }

  Future<void> loadImage() async {
    if (_image == null) {
      _image = await Repository.getPuzzleImage(imageLocation);
    }
  }

  static const double IMAGE_OPACITY_CLEAR = 1.0;
  static const double IMAGE_OPACITY_DIM = .35;

  Puzzle(
      {this.id,
      @required this.name,
      @required this.thumb,
      @required this.imageLocation,
      imageColour,
      imageOpacity,
      numLocked,
      this.maxRc,
      previousMaxPieces}) {
    if (imageColour != null) this.imageColour = imageColour;
    if (imageOpacity != null) this.imageOpacity = imageOpacity;
    if (previousMaxPieces != null) this.previousMaxPieces = previousMaxPieces;
    numLocked = this.numLocked ?? 0;
  }

  Puzzle.fromMap(Map json)
      : assert(json['name'] != null),
        assert(json['image_location'] != null),
        id = json['id'],
        name = json['name'],
        imageLocation = json['image_location'],
        imageOpacity = json['image_opacity'] {
    if (json['max_rows'] != null) {
      this.maxRc = RC(row: json['max_rows'], col: json['max_cols']);
    }
    if (json['num_locked'] != null) {
      this.numLocked = json['num_locked'];
    }
    if (json['previous_max_pieces'] != null) {
      this.previousMaxPieces = json['previous_max_pieces'];
    }
    if (json['thumb'] != null) {
      this.thumb = base64Decode(json['thumb']);
    }
    if (json['image_colour_r'] != null) {
      imageColour = Color.fromRGBO(
          json['image_colour_r'],
          json['image_colour_g'],
          json['image_colour_b'],
          json['image_opacity'] ?? IMAGE_OPACITY_DIM);
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
        maxRc: this.maxRc,
        numLocked: this.numLocked,
        previousMaxPieces: this.previousMaxPieces);
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
        'maxPieces: $maxPieces, numLocked: $numLocked, maxRc: $maxRc}';
  }

  PlayState get playState {
    return (maxPieces ?? 0) > 0
        ? PlayState.inProgress
        : PlayState.notInProgress;
  }
}

enum PlayState { inProgress, notInProgress }
