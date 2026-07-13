import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

final class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

Future<void> main() async {
  final logger = ISpectLogger();
  Bloc.observer = ISpectBlocObserver(logger: logger);

  final counter = CounterCubit()..increment();
  await counter.close();
}
