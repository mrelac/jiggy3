// You may not need this if AlbumsBloc (renamed ChooserBloc?) is a better place.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// const double THUMB_WIDTH = 120.0;

class ChooserService {
  /// Read asset ("asset"), network ("http"), or file ("/") asset bytes,
  /// depending on what location starts with
  static Future<Uint8List> readImageBytesFromLocation(String location) async {
    Uint8List fullBytes;
    if (location.startsWith("assets")) {
      fullBytes = (await rootBundle.load(location)).buffer.asUint8List();
    } else if (location.startsWith("http")) {
      fullBytes = (await NetworkAssetBundle(Uri.parse(location)).load(location))
          .buffer
          .asUint8List();
    } else if (location.startsWith("/")) {
      fullBytes = await File(location).readAsBytes();
    } else {
      throw Exception('Unsupported image path $location');
    }
    return fullBytes;
  }

  static const DEFAULT_DATE_FORMAT_FILE = 'yyyy-MM-dd_HH.mm.ss';
  static const DEFAULT_DATE_FORMAT_DISPLAY = 'yyyy-MM-dd HH:mm:ss';

  // Prints a string with the given prefix, dateFormat, and date, if supplied.
  /// Defaults:
  ///   prefix: ''
  ///   dateFormat: DEFAULT_DATE_FORMAT_DISPLAY (e.g. yyyy-MM-dd HH:mm:ss)
  ///   date: current date and time
  static void printTime({String prefix, String dateFormat, DateTime date}) {
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
    return '${prefix ?? ""}_$formattedDate';
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
}
