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

  static void printTime(String prefix, [DateTime date]) {
    final formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(date ?? DateTime.now());
    print('$prefix: $formattedDate');
  }

  static String generateUniqueName(String prefix, List<String> excludedNames) {
    prefix = prefix ?? 'New';
    int i = 1;
    String name = '${prefix} ' + i.toString();
    while (excludedNames.contains(name)) {
      name = '${prefix} ' + (++i).toString();
    }
    return name;
  }
}
