import 'package:bloc/bloc.dart';

/// Configuration settings for controlling Bloc lifecycle logging.
///
/// The `ISpectBlocSettings` class allows customization of what types of
/// Bloc lifecycle events should be logged and how the logs should be formatted.
class ISpectBlocSettings {
  /// Creates an instance of `ISpectBlocSettings`.
  ///
  /// - `enabled`: If `true`, logging is enabled. Defaults to `true`.
  /// - `printEvents`: If `true`, logs events received by the Bloc. Defaults to `true`.
  /// - `printTransitions`: If `true`, logs state transitions. Defaults to `true`.
  /// - `printChanges`: If `true`, logs state changes. Defaults to `false`.
  /// - `printEventFullData`: If `true`, logs full event data. Defaults to `true`.
  /// - `printStateFullData`: If `true`, logs full state data. Defaults to `true`.
  /// - `printCreations`: If `true`, logs Bloc creation events. Defaults to `false`.
  /// - `printClosings`: If `true`, logs Bloc closing events. Defaults to `false`.
  /// - `transitionFilter`: A filter function to determine if a transition should be logged.
  /// - `eventFilter`: A filter function to determine if an event should be logged.
  const ISpectBlocSettings({
    this.enabled = true,
    this.printEvents = true,
    this.printTransitions = true,
    this.printChanges = true,
    this.printEventFullData = true,
    this.printCreations = true,
    this.printClosings = true,
    this.transitionFilter,
    this.eventFilter,
  });

  /// Whether logging is enabled.
  final bool enabled;

  /// Whether to log events received by the Bloc.
  final bool printEvents;

  /// Whether to log state transitions.
  final bool printTransitions;

  /// Whether to log state changes.
  final bool printChanges;

  /// Whether to log full event data.
  final bool printEventFullData;

  /// Whether to log Bloc creation events.
  final bool printCreations;

  /// Whether to log Bloc closing events.
  final bool printClosings;

  /// A filter function for state transitions.
  ///
  /// If provided, this function is called for each transition. If it returns
  /// `true`, the transition is logged; otherwise, it is skipped.
  final bool Function(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  )? transitionFilter;

  /// A filter function for events.
  ///
  /// If provided, this function is called for each event. If it returns `true`,
  /// the event is logged; otherwise, it is skipped.
  final bool Function(Bloc<dynamic, dynamic> bloc, Object? event)? eventFilter;
}
