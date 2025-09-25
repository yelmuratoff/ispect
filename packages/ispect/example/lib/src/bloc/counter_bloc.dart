import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CounterEvent {
  const CounterEvent();
}

final class Increment extends CounterEvent {
  const Increment();
}

final class Decrement extends CounterEvent {
  const Decrement();
}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }
}
