part of 'base.dart';

final class BlocStateLog extends BlocLifecycleLog {
  BlocStateLog({
    required super.bloc,
    required this.change,
    required this.settings,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final currentPayload = settings.printStateFullData
                ? change.currentState
                : change.currentState.runtimeType;
            final nextPayload = settings.printStateFullData
                ? change.nextState
                : change.nextState.runtimeType;
            return '${bloc.runtimeType} emitted a change'
                '\nCURRENT state: $currentPayload'
                '\nNEXT state: $nextPayload';
          },
          additionalData: <String, dynamic>{
            'currentState': change.currentState,
            'nextState': change.nextState,
          },
        );

  final Change<dynamic> change;
  final ISpectBlocSettings settings;

  static const String logKey = 'bloc-state';
}
