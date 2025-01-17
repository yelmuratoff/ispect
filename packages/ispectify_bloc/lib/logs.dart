import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/settings.dart';

class BlocEventLog extends ISpectifyLog {
  BlocEventLog({
    required this.bloc,
    required this.event,
    required this.settings,
  }) : super(
          key: getKey,
          settings.printEventFullData
              ? '${bloc.runtimeType} receive event:\n$event'
              : '${bloc.runtimeType} receive event: ${event.runtimeType}',
          title: getKey,
        );

  final Bloc<dynamic, dynamic> bloc;
  final Object? event;
  final ISpectifyBlocSettings settings;

  static const getKey = 'bloc-event';

  @override
  String get textMessage {
    final sb = StringBuffer()..write(message);
    return sb.toString();
  }
}

class BlocStateLog extends ISpectifyLog {
  BlocStateLog({
    required this.bloc,
    required this.transition,
    required this.settings,
  }) : super(
          key: getKey,
          '${bloc.runtimeType} with event ${transition.event.runtimeType}',
          title: getKey,
        );

  final Bloc<dynamic, dynamic> bloc;
  final Transition<dynamic, dynamic> transition;
  final ISpectifyBlocSettings settings;

  static const getKey = 'bloc-state';

  @override
  String get textMessage {
    final sb = StringBuffer()
      ..write(message)
      ..write(
        '\nCURRENT state: ${settings.printStateFullData ? '\n${transition.currentState}' : transition.currentState.runtimeType}',
      )
      ..write(
        '\nNEXT state: ${settings.printStateFullData ? '\n${transition.nextState}' : transition.nextState.runtimeType}',
      );
    return sb.toString();
  }
}

class BlocChangeLog extends ISpectifyLog {
  BlocChangeLog({
    required this.bloc,
    required this.change,
    required this.settings,
  }) : super(
          key: getKey,
          '${bloc.runtimeType} changed',
          title: getKey,
        );

  final BlocBase<dynamic> bloc;
  final Change<dynamic> change;
  final ISpectifyBlocSettings settings;

  static const getKey = 'bloc-transition';

  @override
  String get textMessage {
    final sb = StringBuffer()
      ..write(message)
      ..write(
        '\nCURRENT state: ${settings.printStateFullData ? '\n${change.currentState}' : change.currentState.runtimeType}',
      )
      ..write(
        '\nNEXT state: ${settings.printStateFullData ? '\n${change.nextState}' : change.nextState.runtimeType}',
      );
    return sb.toString();
  }
}

class BlocCreateLog extends ISpectifyLog {
  BlocCreateLog({
    required this.bloc,
  }) : super(
          key: getKey,
          '${bloc.runtimeType} created',
          title: getKey,
        );

  final BlocBase<dynamic> bloc;

  static const getKey = 'bloc-create';

  @override
  String get textMessage {
    final sb = StringBuffer()..write(message);
    return sb.toString();
  }
}

class BlocCloseLog extends ISpectifyLog {
  BlocCloseLog({
    required this.bloc,
  }) : super(
          key: getKey,
          '${bloc.runtimeType} closed',
          title: getKey,
        );

  final BlocBase<dynamic> bloc;

  static const getKey = 'bloc-close';

  @override
  String get textMessage {
    final sb = StringBuffer()..write(message);
    return sb.toString();
  }
}
