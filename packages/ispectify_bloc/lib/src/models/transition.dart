part of 'base.dart';

final class BlocTransitionLog extends BlocLifecycleLog {
  BlocTransitionLog({
    required Bloc<dynamic, dynamic> super.bloc,
    required this.transition,
    required this.settings,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final eventPayload = settings.printEventFullData
                ? transition.event
                : transition.event.runtimeType;
            final currentPayload = settings.printStateFullData
                ? transition.currentState
                : transition.currentState.runtimeType;
            final nextPayload = settings.printStateFullData
                ? transition.nextState
                : transition.nextState.runtimeType;
            return '${bloc.runtimeType} processed $eventPayload'
                '\nCURRENT state: $currentPayload'
                '\nNEXT state: $nextPayload';
          },
          additionalData: <String, dynamic>{
            'event': transition.event,
            'currentState': transition.currentState,
            'nextState': transition.nextState,
          },
        );

  final Transition<dynamic, dynamic> transition;
  final ISpectBlocSettings settings;

  static const String logKey = 'bloc-transition';
}

typedef BlocChangeLog = BlocTransitionLog;
