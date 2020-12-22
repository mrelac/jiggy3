import 'dart:async';

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
    } else if (originalValue == newText) {
      _textStreamController.sink.add(newText);
    } else if (_excludedNames.contains(newText.toLowerCase())) {
      _textStreamController.addError('Name exists. Please choose another.');
    } else {
      _textStreamController.add(newText);
    }
  }

  dispose() {
    // FIXME FIXME FIXME
    print('EditingNameBloc: DISPOSING...');
    _textStreamController.close();
  }
}
