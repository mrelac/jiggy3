import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:path/path.dart' as pathfuncs;
import 'package:path_provider/path_provider.dart';

class JiggyFilesystem {
  static String _appImagesDirectory;

  static Future<String> get appImagesDirectory async =>
      _appImagesDirectory ?? await _getAppImagesDirectory();

  static Future<void> appImagesDirectoryDelete() async {
    await Directory(await appImagesDirectory).delete(recursive: true);
  }

  static Future<void> appImagesDirectoryCreate() async {
    await Directory(await appImagesDirectory).create();
  }

  static Future<void> imageBytesSave(Uint8List bytes, File target) async {
    await target.writeAsBytes(bytes, mode: FileMode.write);
  }

  static Future<void> imageFileDelete(File imageFile) async {
    await imageFile.delete();
  }

  // PRIVATE METHODS

  static Future<String> _getAppImagesDirectory() async {
    String appDir;
    try {
      Directory appDocumentsDirectory = await getExternalStorageDirectory();
      appDir = appDocumentsDirectory.path;
    } catch (e) {
      // For IOS, which throws an error on getExternalStorageDirectory().
      Directory d = await getApplicationDocumentsDirectory();
      appDir = d.path;
    }

    return join(appDir, 'images');
  }

  /// Return the fully qualified image file path name, including image
  /// file and extension. E.g.:
  ///   name: Birmingham => '/app/Images/Directory/Path/Birmingham.jpg'
  /// NOTE: any path parts and any extension for 'name' are ignored.
  static Future<String> createTargetImagePath(String name) async {
    String nameNoExtension = pathfuncs.basenameWithoutExtension(name);
    return await appImagesDirectory + '/$nameNoExtension.jpg';
  }
}
