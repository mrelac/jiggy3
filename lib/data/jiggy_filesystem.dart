import 'dart:io';
import 'dart:typed_data';

import 'package:jiggy3/services/utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class JiggyFilesystem {
  static String _directoryImages;

  static Future<String> get directoryImagesGet async {
    if (_directoryImages == null) {
      _directoryImages = await _appDirectoryGet() + '/images';
    }
    return _directoryImages;
  }

  static Future<void> directoryPicturesDelete() async {
    Directory d = Directory(await _appDirectoryGet() + '/Pictures');
    if (await d.exists()) {
      print('Deleting directory "${d.path}"');
      await d.delete(recursive: true);
    }
  }

  static Future<void> directoryImagesDelete() async {
    Directory d = Directory(await directoryImagesGet);
    if (await d.exists()) {
      print('Deleting directory "${d.path}"');
      await d.delete(recursive: true);
    }
  }

  static Future<void> directoryImagesCreate() async {
    await Directory(await directoryImagesGet).create();
  }

  static Future<void> bytesImageSave(Uint8List bytes, File target) async {
    await target.writeAsBytes(bytes, mode: FileMode.write);
  }

  static Future<void> fileImageDelete(File imageFile) async {
    await imageFile.delete();
    print('Deleted image file ${imageFile.path}');
  }

  // PRIVATE METHODS

  static Future<String> _appDirectoryGet() async {
    String appDir;
    try {
      Directory appDocumentsDirectory = await getExternalStorageDirectory();
      appDir = appDocumentsDirectory.path;
    } catch (e) {
      // For IOS, which throws an error on getExternalStorageDirectory().
      Directory d = await getApplicationDocumentsDirectory();
      appDir = d.path;
    }
    return appDir;
  }

  /// Return the fully qualified image file path name with date and time
  /// appended (to make the file unique). The resulting path includes image
  /// file and extension. E.g.:
  ///   name: Birmingham => '/app/Images/Directory/Path/Birmingham_2020.12.28_09.16.00.jpg'
  /// NOTE: any path parts and any extension for 'name' are ignored.
  static Future<String> createTargetImagePath(String name) async {
    String nameNoExtension = basenameWithoutExtension(name);
    // return await appImagesDirectory + '/$nameNoExtension.jpg';

    final prefix = basenameWithoutExtension(name);
    final targetImagePath = await directoryImagesGet +
        '/${Utils.createDateString(prefix: prefix)}.jpg';
    return targetImagePath;
  }
}
