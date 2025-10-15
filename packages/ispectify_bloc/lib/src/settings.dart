import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

typedef ISpectBlocTransitionFilter = bool Function(
  Bloc<dynamic, dynamic> bloc,
  Transition<dynamic, dynamic> transition,
);

typedef ISpectBlocEventFilter = bool Function(
  Bloc<dynamic, dynamic> bloc,
  Object? event,
);

typedef ISpectBlocChangeFilter = bool Function(
  BlocBase<dynamic> bloc,
  Change<dynamic> change,
);

/// Configuration settings for controlling Bloc lifecycle logging.
@immutable
class ISpectBlocSettings {
  /// Creates an instance of `ISpectBlocSettings`.
  const ISpectBlocSettings({
    this.enabled = true,
    this.printEvents = true,
    this.printTransitions = true,
    this.printChanges = true,
    this.printCompletions = true,
    this.printCreations = true,
    this.printClosings = true,
    this.printErrors = true,
    this.printEventFullData = true,
    this.printStateFullData = false,
    this.transitionFilter,
    this.eventFilter,
    this.changeFilter,
  });

  /// Turns off all logging.
  static const ISpectBlocSettings silent = ISpectBlocSettings(enabled: false);

  /// Logs creation, transitions, and errors only.
  static const ISpectBlocSettings minimal = ISpectBlocSettings(
    printChanges: false,
    printCompletions: false,
  );

  /// Logs every lifecycle event with full payloads.
  static const ISpectBlocSettings verbose = ISpectBlocSettings(
    printStateFullData: true,
  );

  /// Whether logging is enabled.
  final bool enabled;

  /// Whether to log events received by the Bloc.
  final bool printEvents;

  /// Whether to log state transitions.
  final bool printTransitions;

  /// Whether to log state changes.
  final bool printChanges;

  /// Whether to log lifecycle completions triggered by event handlers.
  final bool printCompletions;

  /// Whether to log Bloc creation events.
  final bool printCreations;

  /// Whether to log Bloc closing events.
  final bool printClosings;

  /// Whether to log Bloc errors.
  final bool printErrors;

  /// Whether to log full event payloads instead of only the runtime type.
  final bool printEventFullData;

  /// Whether to log full state payloads instead of only the runtime type.
  final bool printStateFullData;

  /// A filter function for state transitions.
  ///
  /// If provided, this function is called for each transition. If it returns
  /// `true`, the transition is logged; otherwise, it is skipped.
  final ISpectBlocTransitionFilter? transitionFilter;

  /// A filter function for events.
  ///
  /// If provided, this function is called for each event. If it returns `true`,
  /// the event is logged; otherwise, it is skipped.
  final ISpectBlocEventFilter? eventFilter;

  /// A filter function for change notifications.
  ///
  /// If provided, this function is called for each change. If it returns `true`,
  /// the change is logged; otherwise, it is skipped.
  final ISpectBlocChangeFilter? changeFilter;

  /// Returns a copy with the provided overrides.
  ISpectBlocSettings copyWith({
    bool? enabled,
    bool? printEvents,
    bool? printTransitions,
    bool? printChanges,
    bool? printCompletions,
    bool? printCreations,
    bool? printClosings,
    bool? printErrors,
    bool? printEventFullData,
    bool? printStateFullData,
    ISpectBlocTransitionFilter? transitionFilter,
    ISpectBlocEventFilter? eventFilter,
    ISpectBlocChangeFilter? changeFilter,
  }) =>
      ISpectBlocSettings(
        enabled: enabled ?? this.enabled,
        printEvents: printEvents ?? this.printEvents,
        printTransitions: printTransitions ?? this.printTransitions,
        printChanges: printChanges ?? this.printChanges,
        printCompletions: printCompletions ?? this.printCompletions,
        printCreations: printCreations ?? this.printCreations,
        printClosings: printClosings ?? this.printClosings,
        printErrors: printErrors ?? this.printErrors,
        printEventFullData: printEventFullData ?? this.printEventFullData,
        printStateFullData: printStateFullData ?? this.printStateFullData,
        transitionFilter: transitionFilter ?? this.transitionFilter,
        eventFilter: eventFilter ?? this.eventFilter,
        changeFilter: changeFilter ?? this.changeFilter,
      );
}
