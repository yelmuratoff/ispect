import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/settings.dart';

class BlocTransitionLog extends ISpectifyData {
  BlocTransitionLog({
    required this.bloc,
    required this.transition,
    required this.settings,
  }) : super(
          () {
            final buffer = StringBuffer()
              ..write('${bloc.runtimeType} processed ')
              ..write(
                settings.printEventFullData
                    ? transition.event
                    : transition.event.runtimeType,
              )
              ..write('\nCURRENT state: ')
              ..write(
                settings.printStateFullData
                    ? transition.currentState
                    : transition.currentState.runtimeType,
              )
              ..write('\nNEXT state: ')
              ..write(
                settings.printStateFullData
                    ? transition.nextState
                    : transition.nextState.runtimeType,
              );
            return buffer.toString();
          }(),
          key: logKey,
          title: logKey,
          additionalData: <String, dynamic>{
            'event': transition.event,
            'currentState': transition.currentState,
            'nextState': transition.nextState,
          },
        );

  final Bloc<dynamic, dynamic> bloc;
  final Transition<dynamic, dynamic> transition;
  final ISpectBlocSettings settings;

  static const String logKey = 'bloc-transition';
}

typedef BlocChangeLog = BlocTransitionLog;
