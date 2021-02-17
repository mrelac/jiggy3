import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jiggy3/widgets/piece.dart';

class Utils {
  static const DEFAULT_DATE_FORMAT_FILE = 'yyyy-MM-dd_HH.mm.ss';
  static const DEFAULT_DATE_FORMAT_DISPLAY = 'yyyy-MM-dd HH:mm:ss';
  static const DEFAULT_TIIME_FORMAT = 'HH:mm:ss';

  // Prints a string with the given prefix, dateFormat, and date, if supplied.
  /// Defaults:
  ///   prefix: ''
  ///   dateFormat: DEFAULT_DATE_FORMAT_DISPLAY (e.g. yyyy-MM-dd HH:mm:ss)
  ///   date: current date and time
  static void printDateTime({String prefix, String dateFormat, DateTime date}) {
    print(createDateString(prefix: prefix, dateFormat: dateFormat, date: date));
  }

  // Returns a string with the given prefix, dateFormat, and date, if supplied.
  /// Defaults:
  ///   prefix: ''
  ///   dateFormat: DEFAULT_DATE_FORMAT_FILE (e.g. yyyy-MM-dd_HH.mm.ss)
  ///   date: current date and time
  static String createDateString(
      {String prefix, String dateFormat, DateTime date}) {
    final formattedDate = DateFormat(dateFormat ?? DEFAULT_DATE_FORMAT_FILE)
        .format(date ?? DateTime.now());
    return '${prefix ?? ""}$formattedDate';
  }

  static String generateUniqueName(String prefix, List<String> excludedNames) {
    prefix = prefix ?? 'New';
    int i = 1;
    String name = '$prefix ' + i.toString();
    while (excludedNames.contains(name)) {
      name = '$prefix ' + (++i).toString();
    }
    return name;
  }

  static Offset getPosition(GlobalKey key) {
    final RenderBox renderBox = key.currentContext.findRenderObject();
    return renderBox.localToGlobal(Offset.zero);
  }

  static Size getSize(GlobalKey key) {
    final RenderBox renderBox = key.currentContext?.findRenderObject();
    return renderBox?.size;
  }

  static int findClosestLvElement(List<Piece> lvPieces, bool isVerticalListview, Offset piecePos) {
    if (lvPieces.isEmpty) {
      return 0;
    }
    int nearest;
    for (int i = 0; i < lvPieces.length; i++) {
      Offset offset = Utils.getPosition(lvPieces[i].key);
// print('i: $i, offset: $offset, piecePos: $piecePos');

      if (isVerticalListview) {
        if (offset.dy > piecePos.dy) {
          nearest = max(0, i - 1);
          break;
        } else {
          nearest = i + 1;
        }
      } else {
        if (offset.dx > piecePos.dx) {
          nearest = max(0, i - 1);
          break;
        } else {
          nearest = i + 1;
        }
      }
    }
    return nearest ?? lvPieces.length + 1;
  }

  static void printListviewPieces(List<Piece> lvPieces) {
      for (int i = 0; i < lvPieces.length; i++) {
        Piece p = lvPieces[i];
        try {
          int id = lvPieces[i].puzzlePiece.id;
          bool locked = lvPieces[i].puzzlePiece.locked;
          print(
              '_lvPieces[$i] position (id $id: ${Utils.getPosition(p.key)}, locked: $locked}');
        } catch (e) {
          print('unable to get position for $i');
        }
      }
      print(' ');
  }

  /// Freeze device orientation by image orientation. To unfreeze, omit
  /// the parameter.
  static void setOrientations([bool imageIsLandscape]) {
    final portrait = [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ];
    final landscape = [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];

    final orientations = <DeviceOrientation>[];
    if (imageIsLandscape == null)
      orientations..addAll(portrait)..addAll(landscape);
    else if (imageIsLandscape)
      orientations.addAll(landscape);
    else orientations.addAll(portrait);
    SystemChrome.setPreferredOrientations(orientations);
  }
}
