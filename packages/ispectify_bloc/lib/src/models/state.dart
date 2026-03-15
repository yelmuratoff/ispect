part of 'base.dart';

/// Log emitted when a Bloc or Cubit's state changes.
///
/// Corresponds to [BlocObserver.onChange].
/// Called before the bloc's state is updated with the new value.
/// Includes current and next states, but NOT the triggering event (use [BlocTransitionLog] for that).
final class BlocStateLog extends BlocLifecycleLog {
  BlocStateLog({
    required super.bloc,
    required this.change,
    required this.settings,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final blocType = bloc.runtimeType;
            final currentPayload = settings.printStateFullData
                ? change.currentState
                : change.currentState.runtimeType;
            final nextPayload = settings.printStateFullData
                ? change.nextState
                : change.nextState.runtimeType;
            return '$blocType changed from $currentPayload to $nextPayload';
          },
          additionalData: settings.redactAdditionalData(<String, dynamic>{
            'current-state': change.currentState,
            'next-state': change.nextState,
          }),
        );

  final Change<dynamic> change;
  final ISpectBlocSettings settings;

  static const String logKey = 'bloc-state';
}
