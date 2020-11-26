

/// This file is used for testing state/model persistence using bloc streams.
@deprecated
class CounterRepository {

  CounterRepository._private();

  static int _counterValue;
  static int get counterValue => _counterValue ?? 0;
  static set counterValue(int value) {
    _counterValue = value;
  }
}
