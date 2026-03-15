part of 'base.dart';

/// Log emitted when a Bloc transitions from one state to another in response to an event.
///
/// Corresponds to [BlocObserver.onTransition].
/// Called before the bloc's state is updated.
/// Includes the triggering event, current state, and next state.
/// Only applies to Bloc (not Cubit), as transitions require events.
final class BlocTransitionLog extends BlocLifecycleLog {
  BlocTransitionLog({
    required Bloc<dynamic, dynamic> bloc,
    required this.transition,
    required this.settings,
  }) : super(
          bloc: bloc,
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final blocType = bloc.runtimeType;
            final eventPayload = settings.printEventFullData
                ? transition.event
                : transition.event.runtimeType;
            final currentPayload = settings.printStateFullData
                ? transition.currentState
                : transition.currentState.runtimeType;
            final nextPayload = settings.printStateFullData
                ? transition.nextState
                : transition.nextState.runtimeType;
            return '$blocType transitioned from $currentPayload to $nextPayload'
                '\nEVENT: $eventPayload';
          },
          additionalData: settings.redactAdditionalData(<String, dynamic>{
            'event': transition.event,
            'currentState': transition.currentState,
            'nextState': transition.nextState,
          }),
        );

  final Transition<dynamic, dynamic> transition;
  final ISpectBlocSettings settings;

  static const String logKey = 'bloc-transition';
}
