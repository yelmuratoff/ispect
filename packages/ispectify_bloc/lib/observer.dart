import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/logs.dart';
import 'package:ispectify_bloc/settings.dart';
import 'package:meta/meta.dart';

/// A custom [BlocObserver] implementation that integrates with the ISpectify logging system.
///
/// This observer provides detailed logging for Bloc lifecycle events such as
/// event reception, state transitions, state changes, errors, creation, and closure.
class ISpectifyBlocObserver extends BlocObserver {
  /// Creates an instance of [ISpectifyBlocObserver].
  ///
  /// - [iSpectify]: An optional instance of [ISpectiy] for logging. If not provided,
  ///   a default [ISpectiy] instance is used.
  /// - [settings]: Configuration settings to control the logging behavior.
  ISpectifyBlocObserver({
    ISpectiy? iSpectify,
    this.settings = const ISpectifyBlocSettings(),
  }) {
    _iSpectify = iSpectify ?? ISpectiy();
  }

  late final ISpectiy _iSpectify;
  final ISpectifyBlocSettings settings;

  /// Logs when a [Bloc] receives an event.
  ///
  /// - [bloc]: The [Bloc] receiving the event.
  /// - [event]: The event being received.
  @override
  @mustCallSuper
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!settings.enabled || !settings.printEvents) {
      return;
    }
    final accepted = settings.eventFilter?.call(bloc, event) ?? true;
    if (!accepted) {
      return;
    }
    _iSpectify.logCustom(
      BlocEventLog(
        bloc: bloc,
        event: event,
        settings: settings,
      ),
    );
  }

  /// Logs when a [Bloc] undergoes a state transition.
  ///
  /// - [bloc]: The [Bloc] undergoing the transition.
  /// - [transition]: The transition details.
  @override
  @mustCallSuper
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (!settings.enabled || !settings.printTransitions) {
      return;
    }
    final accepted = settings.transitionFilter?.call(bloc, transition) ?? true;
    if (!accepted) {
      return;
    }
    _iSpectify.logCustom(
      BlocStateLog(
        bloc: bloc,
        transition: transition,
        settings: settings,
      ),
    );
  }

  /// Logs when a [BlocBase] state changes.
  ///
  /// - [bloc]: The [BlocBase] whose state has changed.
  /// - [change]: Details of the state change.
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (!settings.enabled || !settings.printChanges) {
      return;
    }
    _iSpectify.logCustom(
      BlocChangeLog(
        bloc: bloc,
        change: change,
        settings: settings,
      ),
    );
  }

  /// Logs errors occurring in a [BlocBase].
  ///
  /// - [bloc]: The [BlocBase] where the error occurred.
  /// - [error]: The error that occurred.
  /// - [stackTrace]: The stack trace for the error.
  @override
  @mustCallSuper
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _iSpectify.error('${bloc.runtimeType}', error, stackTrace);
  }

  /// Logs when a [BlocBase] is created.
  ///
  /// - [bloc]: The newly created [BlocBase].
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (!settings.enabled || !settings.printCreations) {
      return;
    }
    _iSpectify.logCustom(
      BlocCreateLog(bloc: bloc),
    );
  }

  /// Logs when a [BlocBase] is closed.
  ///
  /// - [bloc]: The [BlocBase] being closed.
  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (!settings.enabled || !settings.printClosings) {
      return;
    }
    _iSpectify.logCustom(
      BlocCloseLog(bloc: bloc),
    );
  }
}
