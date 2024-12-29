import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/settings.dart';

/// A log class for recording Bloc events.
///
/// This log captures when a [Bloc] receives an event and formats
/// the message according to the provided [settings].
class BlocEventLog extends ISpectifyLog {
  /// Creates a log entry for a received Bloc event.
  ///
  /// - [bloc]: The Bloc instance receiving the event.
  /// - [event]: The event received by the Bloc.
  /// - [settings]: Configuration settings for logging behavior.
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
  String get key => ISpectifyLogType.blocEvent.key;

  /// Generates a formatted log message for the event.
  ///
  /// - [timeFormat]: The format to use for the timestamp in the log.
  /// Returns a formatted string representing the event log.
  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    final sb = StringBuffer();
    sb.write(displayTitleWithTime(timeFormat: timeFormat));
    sb.write('\n$message');
    return sb.toString();
  }
}

/// A log class for recording Bloc state transitions.
///
/// This log captures transitions between Bloc states, including
/// the event that triggered the transition.
class BlocStateLog extends ISpectifyLog {
  /// Creates a log entry for a Bloc state transition.
  ///
  /// - [bloc]: The Bloc instance undergoing the transition.
  /// - [transition]: Details of the transition.
  /// - [settings]: Configuration settings for logging behavior.
  BlocStateLog({
    required this.bloc,
    required this.transition,
    required this.settings,
  }) : super('${bloc.runtimeType} with event ${transition.event.runtimeType}');

  final Bloc bloc;
  final Transition transition;
  final ISpectifyBlocSettings settings;

  @override
  String get key => ISpectifyLogType.blocTransition.key;

  /// Generates a formatted log message for the state transition.
  ///
  /// - [timeFormat]: The format to use for the timestamp in the log.
  /// Returns a formatted string representing the state transition log.
  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    final sb = StringBuffer();
    sb.write(displayTitleWithTime(timeFormat: timeFormat));
    sb.write('\n$message');
    sb.write(
        '\nCURRENT state: ${settings.printStateFullData ? '\n${transition.currentState}' : transition.currentState.runtimeType}');
    sb.write(
        '\nNEXT state: ${settings.printStateFullData ? '\n${transition.nextState}' : transition.nextState.runtimeType}');
    return sb.toString();
  }
}

/// A log class for recording Bloc state changes.
///
/// This log captures changes to the Bloc's state without
/// specific transition details.
class BlocChangeLog extends ISpectifyLog {
  /// Creates a log entry for a Bloc state change.
  ///
  /// - [bloc]: The Bloc instance whose state has changed.
  /// - [change]: The details of the state change.
  /// - [settings]: Configuration settings for logging behavior.
  BlocChangeLog({
    required this.bloc,
    required this.change,
    required this.settings,
  }) : super('${bloc.runtimeType} changed');

  final BlocBase bloc;
  final Change change;
  final ISpectifyBlocSettings settings;

  @override
  String get key => ISpectifyLogType.blocTransition.key;

  /// Generates a formatted log message for the state change.
  ///
  /// - [timeFormat]: The format to use for the timestamp in the log.
  /// Returns a formatted string representing the state change log.
  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    final sb = StringBuffer();
    sb.write(displayTitleWithTime(timeFormat: timeFormat));
    sb.write('\n$message');
    sb.write(
        '\nCURRENT state: ${settings.printStateFullData ? '\n${change.currentState}' : change.currentState.runtimeType}');
    sb.write('\nNEXT state: ${settings.printStateFullData ? '\n${change.nextState}' : change.nextState.runtimeType}');
    return sb.toString();
  }
}

/// A log class for recording the creation of a Bloc instance.
///
/// This log captures when a Bloc is created.
class BlocCreateLog extends ISpectifyLog {
  /// Creates a log entry for the creation of a Bloc.
  ///
  /// - [bloc]: The newly created Bloc instance.
  BlocCreateLog({
    required this.bloc,
  }) : super('${bloc.runtimeType} created');

  final BlocBase bloc;

  @override
  String? get key => ISpectifyLogType.blocCreate.key;

  /// Generates a formatted log message for the Bloc creation.
  ///
  /// - [timeFormat]: The format to use for the timestamp in the log.
  /// Returns a formatted string representing the Bloc creation log.
  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    final sb = StringBuffer();
    sb.write(displayTitleWithTime(timeFormat: timeFormat));
    sb.write('\n$message');
    return sb.toString();
  }
}

/// A log class for recording the closure of a Bloc instance.
///
/// This log captures when a Bloc is closed.
class BlocCloseLog extends ISpectifyLog {
  /// Creates a log entry for the closure of a Bloc.
  ///
  /// - [bloc]: The Bloc instance being closed.
  BlocCloseLog({
    required this.bloc,
  }) : super('${bloc.runtimeType} closed');

  final BlocBase bloc;

  @override
  String? get key => ISpectifyLogType.blocClose.key;

  /// Generates a formatted log message for the Bloc closure.
  ///
  /// - [timeFormat]: The format to use for the timestamp in the log.
  /// Returns a formatted string representing the Bloc closure log.
  @override
  String generateTextMessage({
    TimeFormat timeFormat = TimeFormat.timeAndSeconds,
  }) {
    final sb = StringBuffer();
    sb.write(displayTitleWithTime(timeFormat: timeFormat));
    sb.write('\n$message');
    return sb.toString();
  }
}
