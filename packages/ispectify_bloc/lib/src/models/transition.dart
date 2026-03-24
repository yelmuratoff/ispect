part of 'base.dart';

/// Log emitted when a Bloc transitions from one state to another in response to an event.
///
/// Corresponds to [BlocObserver.onTransition].
/// Called before the bloc's state is updated.
/// Includes the triggering event, current state, and next state.
/// Only applies to Bloc (not Cubit), as transitions require events.
final class BlocTransitionLog extends BlocLifecycleLog {
  factory BlocTransitionLog({
    required Bloc<dynamic, dynamic> bloc,
    required Transition<dynamic, dynamic> transition,
    required ISpectBlocSettings settings,
  }) {
    final typeName = bloc.runtimeType.toString();
    return BlocTransitionLog._internal(
      bloc: bloc,
      transition: transition,
      settings: settings,
      typeName: typeName,
    );
  }

  BlocTransitionLog._internal({
    required Bloc<dynamic, dynamic> bloc,
    required this.transition,
    required this.settings,
    required String typeName,
  }) : super(
          bloc: bloc,
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final eventPayload = settings.formatEvent(transition.event);
            final currentPayload =
                settings.formatState(transition.currentState);
            final nextPayload = settings.formatState(transition.nextState);
            return '$typeName transitioned from $currentPayload to $nextPayload'
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
