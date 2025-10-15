import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/settings.dart';

class BlocStateLog extends ISpectifyData {
  BlocStateLog({
    required this.bloc,
    required this.change,
    required this.settings,
  }) : super(
          () {
            final buffer = StringBuffer()
              ..write('${bloc.runtimeType} emitted a change')
              ..write('\nCURRENT state: ')
              ..write(
                settings.printStateFullData
                    ? change.currentState
                    : change.currentState.runtimeType,
              )
              ..write('\nNEXT state: ')
              ..write(
                settings.printStateFullData
                    ? change.nextState
                    : change.nextState.runtimeType,
              );
            return buffer.toString();
          }(),
          key: getKey,
          title: getKey,
        );

  final BlocBase<dynamic> bloc;
  final Change<dynamic> change;
  final ISpectBlocSettings settings;

  static const getKey = 'bloc-state';
}
