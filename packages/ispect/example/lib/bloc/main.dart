import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/examples/example_app.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

void main() {
  final logger = ISpectFlutter.init();
  final navigatorObserver = ISpectNavigatorObserver();
  ISpect.run(
    () => runApp(
      BlocProvider(
        create: (_) => _CounterCubit(),
        child: buildExampleApp(
          title: 'ISpect BLoC example',
          observer: navigatorObserver,
          home: const _BlocPage(),
        ),
      ),
    ),
    logger: logger,
    onInit: () => Bloc.observer = ISpectBlocObserver(logger: logger),
  );
}

final class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

final class _BlocPage extends StatelessWidget {
  const _BlocPage();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('BLoC diagnostics')),
        body: Center(
          child: BlocBuilder<_CounterCubit, int>(
            builder: (context, count) => ElevatedButton(
              onPressed: context.read<_CounterCubit>().increment,
              child: Text('Increment: $count'),
            ),
          ),
        ),
      );
}
