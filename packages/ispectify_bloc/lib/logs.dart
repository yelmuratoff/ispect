import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/settings.dart';

class BlocEventLog extends ISpectifyLog {
  BlocEventLog({
    required this.bloc,
    required this.event,
    required this.settings,
  }) : super(settings.printEventFullData
            ? '${bloc.runtimeType} receive event:\n$event'
            : '${bloc.runtimeType} receive event: ${event.runtimeType}');

  final Bloc bloc;
  final Object? event;
  final ISpectifyBlocSettings settings;

  @override
  String get key => getKey;

  static const getKey = 'bloc-event';

  @override
  String get textMessage {
    final sb = StringBuffer();
    sb.write(header);
    sb.write('\n$message');
    return sb.toString();
  }
}

class BlocStateLog extends ISpectifyLog {
  BlocStateLog({
    required this.bloc,
    required this.transition,
    required this.settings,
  }) : super('${bloc.runtimeType} with event ${transition.event.runtimeType}');

  final Bloc bloc;
  final Transition transition;
  final ISpectifyBlocSettings settings;

  @override
  String get key => getKey;

  static const getKey = 'bloc-state';

  @override
  String get textMessage {
    final sb = StringBuffer();
    sb.write(header);
    sb.write('\n$message');
    sb.write(
        '\nCURRENT state: ${settings.printStateFullData ? '\n${transition.currentState}' : transition.currentState.runtimeType}');
    sb.write(
        '\nNEXT state: ${settings.printStateFullData ? '\n${transition.nextState}' : transition.nextState.runtimeType}');
    return sb.toString();
  }
}

class BlocChangeLog extends ISpectifyLog {
  BlocChangeLog({
    required this.bloc,
    required this.change,
    required this.settings,
  }) : super('${bloc.runtimeType} changed');

  final BlocBase bloc;
  final Change change;
  final ISpectifyBlocSettings settings;

  @override
  String get key => getKey;

  static const getKey = 'bloc-transition';

  @override
  String get textMessage {
    final sb = StringBuffer();
    sb.write(header);
    sb.write('\n$message');
    sb.write(
        '\nCURRENT state: ${settings.printStateFullData ? '\n${change.currentState}' : change.currentState.runtimeType}');
    sb.write('\nNEXT state: ${settings.printStateFullData ? '\n${change.nextState}' : change.nextState.runtimeType}');
    return sb.toString();
  }
}

class BlocCreateLog extends ISpectifyLog {
  BlocCreateLog({
    required this.bloc,
  }) : super('${bloc.runtimeType} created');

  final BlocBase bloc;

  @override
  String? get key => getKey;

  static const getKey = 'bloc-create';

  @override
  String get textMessage {
    final sb = StringBuffer();
    sb.write(header);
    sb.write('\n$message');
    return sb.toString();
  }
}

class BlocCloseLog extends ISpectifyLog {
  BlocCloseLog({
    required this.bloc,
  }) : super('${bloc.runtimeType} closed');

  final BlocBase bloc;

  @override
  String? get key => getKey;

  static const getKey = 'bloc-close';

  @override
  String get textMessage {
    final sb = StringBuffer();
    sb.write(header);
    sb.write('\n$message');
    return sb.toString();
  }
}
