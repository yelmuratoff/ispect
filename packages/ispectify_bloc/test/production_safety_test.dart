import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:test/test.dart';

final class _ProductionCubit extends Cubit<int> {
  _ProductionCubit() : super(0);
}

void main() {
  test(
    'debug override cannot bypass the omitted compile-time flag',
    () async {
      expect(kISpectEnabled, isFalse);

      final logger = FakeISpectLogger();
      final cubit = _ProductionCubit();
      var callbackInvoked = false;
      ISpectBlocObserver.debugEnabledOverride = true;
      addTearDown(() {
        ISpectBlocObserver.debugEnabledOverride = null;
      });
      addTearDown(cubit.close);

      ISpectBlocObserver(
        logger: logger,
        onBlocCreate: (_) => callbackInvoked = true,
      ).onCreate(cubit);

      expect(callbackInvoked, isFalse);
      expect(logger.traces, isEmpty);
    },
    skip: kISpectEnabled,
  );
}
