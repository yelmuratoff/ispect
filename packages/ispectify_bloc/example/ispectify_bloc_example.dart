// ignore_for_file: unreachable_from_main

import 'package:bloc/bloc.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

void main() async {
  Bloc.observer = ISpectifyBlocObserver(
    settings: const ISpectifyBlocSettings(
      printEventFullData: false,
    ),
  );
  final somethingBloc = SomethingBloc()
    ..add(const LoadSomething(LoadSomethingCase.successful));
  await Future<void>.delayed(const Duration(milliseconds: 300));
  somethingBloc.add(const LoadSomething(LoadSomethingCase.failure));
}

enum LoadSomethingCase { successful, failure }

class SomethingBloc extends Bloc<SomethingEvent, SomethingState> {
  SomethingBloc() : super(SomethingInitial()) {
    on<LoadSomething>((event, emit) {
      emit(SomethingLoading());
      if (event.loadCase == LoadSomethingCase.successful) {
        emit(SomethingLoaded());
        return;
      }
      throw Exception('Load something failure');
    });
  }
}

abstract class SomethingEvent {
  const SomethingEvent();
}

class LoadSomething extends SomethingEvent {
  const LoadSomething(this.loadCase);

  final LoadSomethingCase loadCase;
}

abstract class SomethingState {}

class SomethingInitial extends SomethingState {}

class SomethingLoading extends SomethingState {}

class SomethingLoaded extends SomethingState {}

class SomethingLoadingFailure extends SomethingState {
  SomethingLoadingFailure(this.error);
  final Object? error;
}
