import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jiggy3/data/repository.dart';
import 'package:jiggy3/models/puzzle_piece.dart';

//enum PlayState { neverPlayed, inProgress, completed, notPlayable }

// NOTE: EXECUTIVE DECISION: All puzzle images will be transformed to jpg,
//                           regardless where they came from (e.g. network images - create jpg file), so ImageProvider is File
//       EXECUTIVE DECISION: All puzzle image heights will be transformed to (portrait: 1024; landscape: 768)
//       EXECUTIVE DECISION: All puzzle image widths will be transformed to height * aspectRatio

class Puzzle {
  int id;
  String name;
  Uint8List thumb;
  String imageLocation;
  double imageWidth;
  double imageHeight;
  Color imageColour = Color.fromRGBO(0xff, 0xff, 0xff, IMAGE_OPACITY_CLEAR);
  double imageOpacity = IMAGE_OPACITY_CLEAR;

  // # of pieces locked to win game. -1 means 'Game not yet started'.
  int maxPieces = -1;
  final piecesLocked = <PuzzlePiece>[]; // Correctly-placed pieces
  final piecesLoose = <PuzzlePiece>[]; // Unplayed pieces

  bool get isPortrait => imageHeight < imageWidth;

  FileImage get fileImage => image.image as FileImage;

  Image _image;

  Image get image {
    if (_image == null) {
      _image =
          Repository.getPuzzleImage(imageLocation, imageHeight, imageWidth);
    }
    return _image;
  }

  static const double IMAGE_OPACITY_CLEAR = 1.0;

  Puzzle(
      {this.id,
      @required this.name,
      @required this.thumb,
      @required this.imageLocation,
      @required this.imageWidth,
      @required this.imageHeight,
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
        imageWidth = json['image_width'],
        imageHeight = json['image_height'],
        imageOpacity = json['image_opacity'] {
    if (json['max_pieces'] != null) {
      this.maxPieces = json['max_pieces'];
    }
    if (json['thumb'] != null) {
      // FIXME Fix this when you figure out what's breaking. This hack handles both assets and crops for now.
      // When loading assets, if you don't use base64Decode like this:
      //    this.thumb = base64Decode(json['thumb']);
      // dart throws "Unhandled Exception: type 'String' is not a subtype of type 'Uint8List'"
      // but after cropping and saving the new, cropped image, using base64Decode,
      // dart throws "Unhandled Exception: type '_Uint8ArrayView' is not a subtype of type 'String'".
      // So you must remove the decode:
      //    this.thumb = json['thumb'];
      //
      // Loading asset thumbs only work with base64Decode, but after
      // crop, base64Decode
      try {
        this.thumb = base64Decode(json['thumb']);
        print("LOADED THUMB FOR $name USING base64Decode!");
      } catch (e) {
        print('EXCEPTION: e: ${e}');
        print("LOADING ${name} base64Decode FAILED! LOADING WITHOUT DECODING!");
        this.thumb = json['thumb'];
      }
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
        imageWidth: this.imageWidth,
        imageHeight: this.imageHeight,
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
        'imageWidth: $imageWidth, imageHeight: $imageHeight, '
        'maxPieces: $maxPieces}';
  }

  PlayState get playState {
    if (maxPieces == -1) {
      return PlayState.neverPlayed;
    } else if (piecesLocked.length == maxPieces) {
      return PlayState.completed;
    } else {
      return PlayState.inProgress;
    }
  }
}

enum PlayState { neverPlayed, inProgress, completed, notPlayable }
