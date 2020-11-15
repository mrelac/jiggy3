import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

//enum PlayState { neverPlayed, inProgress, completed, notPlayable }

// NOTE: EXECUTIVE DECISION: All puzzle images will be transformed to jpg,
//                           regardless where they came from (e.g. network images - create jpg file), so ImageProvider is File
//       EXECUTIVE DECISION: All puzzle image heights will be transformed to (portrait: 1024; landscape: 768)
//       EXECUTIVE DECISION: All puzzle image widths will be transformed to height * aspectRatio

class Puzzle {
  int id;
  String label;
  Uint8List thumb;
  String imageLocation;
  double imageWidth;
  double imageHeight;
  Color imageColour = Color.fromRGBO(0xff, 0xff, 0xff, imageOpacityClear);
  double imageOpacity = imageOpacityClear;
  int maxPieces = -1;   // # of pieces locked to win game. -1 means 'Not yet started'

  bool get isPortrait => imageHeight < imageWidth;

  static const double imageOpacityClear = 1.0;

  Puzzle({
    this.id,
    @required this.label,
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
        assert(json['id'] != null),
        assert(json['label'] != null),
        assert(json['thumb_blob'] != null),
        assert(json['location'] != null),
        assert(json['image_width'] != null),
        assert(json['image_height'] != null),
        assert(json['image_colour_r'] != null),
        assert(json['image_colour_g'] != null),
        assert(json['image_colour_b'] != null),
        assert(json['image_opacity'] != null),

        id = json['id'],
        label = json['label'],
        thumb = base64Decode(json['thumb_blob']),
        imageLocation = json['location'],
        imageWidth = json['image_width'],
        imageHeight = json['image_height'],
        imageColour = Color.fromRGBO(
            json['image_colour_r'],
            json['image_colour_g'],
            json['image_colour_b'],
            json['image_opacity']),
        imageOpacity = json['image_opacity'] {
    File imageFile = File(imageLocation);
    if (json['max_pieces'] != null) {
      this.maxPieces = json['max_pieces'];
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Puzzle &&
              runtimeType == other.runtimeType &&
              label.toLowerCase() == other.label.toLowerCase();

  @override
  int get hashCode => label.hashCode;

  @override
  String toString() {
    return 'Puzzle{id: $id, label: $label, imageLocation: $imageLocation, '
        'imageWidth: $imageWidth, imageHeight: $imageHeight, '
        'maxPieces: $maxPieces}';
  }
}
