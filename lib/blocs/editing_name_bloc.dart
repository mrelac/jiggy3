import 'dart:async';

import 'package:jiggy3/pages/chooser_page.dart';

class EditingNameBloc {
  final _excludedNames = <String>[];
  final _textStreamController = StreamController<String>.broadcast();

  Stream<String> get textStream => _textStreamController.stream;

  set excludedNames(List<String> excludedNames) {
    _excludedNames.clear();
    for (int i = 0; i < excludedNames.length; i++) {
      _excludedNames.add(excludedNames[i].toLowerCase());
    }
  }

  void update(String originalValue, String newText) {
    if (newText == null || newText.isEmpty) {
      _textStreamController.sink.addError('Please enter a value.');
    } else if (newText.length > ChooserPage.MAX_NAME_LENGTH) {
      if (newText.length == ChooserPage.MAX_NAME_LENGTH + 1) {
        _textStreamController.sink.add(newText);
      }
      _textStreamController.sink.addError("Maximum name length is ${ChooserPage.MAX_NAME_LENGTH}.");
    } else if (originalValue == newText) {
      _textStreamController.sink.add(newText);
    } else if (_excludedNames.contains(newText.toLowerCase())) {
      _textStreamController.sink.addError('Name exists. Please choose another.');
    } else {
      _textStreamController.sink.add(newText);
    }
  }

  dispose() {
    _textStreamController.close();
  }
}
