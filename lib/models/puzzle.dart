import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  int maxPieces = -1;   // # of pieces locked to win game. -1 means 'Not yet started'

  bool get isPortrait => imageHeight < imageWidth;

  static const double IMAGE_OPACITY_CLEAR = 1.0;

  Puzzle({
    this.id,
    @required this.name,
    @required this.thumb,
    @required this.imageLocation,
    @required this.imageWidth,
    @required this.imageHeight,
    imageColour,
    imageOpacity,
    maxPieces}) {
    if (imageColour != null)
      this.imageColour = imageColour;
    if (imageOpacity != null)
      this.imageOpacity = imageOpacity;
    if (maxPieces != null)
      this.maxPieces = maxPieces;
  }

  Puzzle.fromMap(Map json) :
        assert(json['name'] != null),
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
}
