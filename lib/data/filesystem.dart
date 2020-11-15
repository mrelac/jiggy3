import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class Filesystem {

  Future<void> imageDirectoryCreate() async {
    Directory(await _getImageDirectoryName()).create();
  }

  Future<void> imageDirectoryDelete() async {
    Directory(await _getImageDirectoryName()).delete();
  }

  Future<bool> imageDirectoryExists() async {
    return Directory(await _getImageDirectoryName()).exists();
  }

  /// Returns true if imageFilename exists; false otherwise.
  /// Uses basename to satisfy the request, so path is ignored if supplied.
  Future<bool> imageFileExists(String imageFilename) async {
    return await File(await _toFqFilename(imageFilename)).exists();
  }

  /// Delete the specified imageFile.
  /// Uses basename to satisfy the request, so path is ignored if supplied.
  Future<void> imageFileDelete(String imageFilename) async {
    return await File(basename(imageFilename)).delete();
  }

  /// Write the specified bytes to the specified imageFilename.
  /// Overwrites any existing file.
  /// Uses basename to satisfy the request, so path is ignored if supplied.
  Future<void> imageFileSave(String imageFilename, Uint8List bytes) async {
    return await File(basename(imageFilename)).writeAsBytes(bytes);
  }

  // PRIVATE METHODS

  Future<String> _getImageDirectoryName() async {
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

  Future<String> _toFqFilename(String imageFilename) async {
    return join(await _getImageDirectoryName(), basename(imageFilename));
  }


  // FIXME DELETE ME
  Future<void> _setGlobalImagesDirectory() async {
    String appDir;
    try {
      Directory appDocumentsDirectory = await getExternalStorageDirectory();
      appDir = appDocumentsDirectory.path;
    } catch (e) {
      // For IOS, which throws an error on getExternalStorageDirectory().
      Directory d = await getApplicationDocumentsDirectory();
      appDir = d.path;
    } finally {
      String appImagesDirectory = '$appDir/images';
      if ( ! await File(appImagesDirectory).exists()) {
        // Delete auto-created 'Pictures' directory if it exists.
        final Directory pictures = Directory('$appDir/Pictures');
        if (await pictures.exists()) {
          await pictures.delete();
        }
        Directory(appImagesDirectory).create();
      }
//      setState(() {
//        globals.appImagesDirectory = appImagesDirectory;
//      });
    }
  }


}