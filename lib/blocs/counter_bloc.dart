import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/counter_repository.dart';
import 'bloc_provider.dart';

enum CounterEvent {increment, decrement }

/// This file is used for testing state/model persistence using bloc streams.
@deprecated
class CounterBloc extends Cubit<int> implements BlocBase {
  CounterBloc() : super(0) {
    _counterStream.sink.add(CounterRepository.counterValue);
  }

  final _counterStream = StreamController<int>();
  Stream<int> get counterStream => _counterStream.stream;
  void setCounter(newValue) => _counterStream.sink.add(newValue);

  void increment() {
    CounterRepository.counterValue = CounterRepository.counterValue + 1;
    _counterStream.sink.add(CounterRepository.counterValue);
    print('increment counter value: ${CounterRepository.counterValue}');
  }

  void decrement() {
    CounterRepository.counterValue = CounterRepository.counterValue - 1;
    _counterStream.sink.add(CounterRepository.counterValue);
    print('increment counter value: ${CounterRepository.counterValue}');
  }

  // All stream controllers you create should be closed within this function
  @override
  void dispose() {
    _counterStream.close();
  }
}
