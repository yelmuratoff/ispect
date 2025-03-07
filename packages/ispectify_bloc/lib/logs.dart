import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/settings.dart';

class BlocEventLog extends ISpectifyData {
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

class BlocStateLog extends ISpectifyData {
  BlocStateLog({
    required this.bloc,
    required this.transition,
    required this.settings,
  }) : super(
          key: getKey,
          '''${bloc.runtimeType} with event ${transition.event.runtimeType}\nCURRENT state: ${transition.currentState.runtimeType}\nNEXT state: ${transition.nextState.runtimeType}''',
          title: getKey,
        );

  final Bloc<dynamic, dynamic> bloc;
  final Transition<dynamic, dynamic> transition;
  final ISpectifyBlocSettings settings;

  static const getKey = 'bloc-state';
}

class BlocChangeLog extends ISpectifyData {
  BlocChangeLog({
    required this.bloc,
    required this.change,
    required this.settings,
  }) : super(
          key: getKey,
          '''${bloc.runtimeType} changed\nCURRENT state: ${change.currentState.runtimeType}\nNEXT state: ${change.nextState.runtimeType}''',
          title: getKey,
        );

  final BlocBase<dynamic> bloc;
  final Change<dynamic> change;
  final ISpectifyBlocSettings settings;

  static const getKey = 'bloc-transition';
}

class BlocCreateLog extends ISpectifyData {
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

class BlocCloseLog extends ISpectifyData {
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
