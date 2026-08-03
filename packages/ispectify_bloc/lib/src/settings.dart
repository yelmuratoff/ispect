import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/safe_type_label.dart';
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
    this.printStateFullData = true,
    this.transitionFilter,
    this.eventFilter,
    this.changeFilter,
    this.enableRedaction = true,
    this.redactor,
    this.captureMode = DiagnosticCaptureMode.balanced,
    this.resourceLimits,
  });

  /// Turns off all logging.
  static const ISpectBlocSettings silent = ISpectBlocSettings(enabled: false);

  /// Logs creation, transitions, and errors only.
  static const ISpectBlocSettings minimal = ISpectBlocSettings(
    printChanges: false,
    printCompletions: false,
  );

  /// Reduces event and state values to coarse type labels.
  static const ISpectBlocSettings compact = ISpectBlocSettings(
    printEventFullData: false,
    printStateFullData: false,
    captureMode: DiagnosticCaptureMode.strict,
  );

  /// Logs every lifecycle event with full redacted payloads.
  static const ISpectBlocSettings verbose = ISpectBlocSettings();

  /// Alias for [verbose].
  static const ISpectBlocSettings development = verbose;

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

  /// Whether to log full event payloads instead of a coarse type label.
  final bool printEventFullData;

  /// Whether to log full state payloads instead of a coarse type label.
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

  /// Whether to apply redaction to sensitive data in log payloads.
  ///
  /// When `true`, [redactor] is used when provided; otherwise
  /// [ISpectRedaction.service] is resolved when an operation runs.
  final bool enableRedaction;

  /// Optional redaction service for masking sensitive data in bloc state/event
  /// payloads before they are logged.
  ///
  /// Leave this `null` to follow [ISpectRedaction.service].
  final RedactionService? redactor;

  /// Controls whether guarded application formatters may run during capture.
  final DiagnosticCaptureMode captureMode;

  /// Optional observer-specific budgets. `null` inherits the logger policy.
  final DiagnosticResourceLimits? resourceLimits;

  /// Whether redaction is active for this configuration.
  bool get isRedactionActive => enableRedaction && ISpectRedaction.enabled;

  /// Applies redaction to an additionalData map if redaction is active.
  ///
  /// Returns a bounded copy using [captureMode]. When redaction is disabled,
  /// values remain unmasked but still cannot bypass outbound byte and
  /// traversal limits. A redaction failure returns an empty map.
  Map<String, dynamic>? redactAdditionalData(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;
    return _prepareAdditionalData(
      data,
      enableRedaction: isRedactionActive,
      redactor: redactor,
      captureMode: captureMode,
      resourceLimits: resourceLimits ?? DiagnosticResourceLimits.balanced,
    );
  }

  /// Formats an event payload for display based on [printEventFullData].
  ///
  /// Returns the full object when verbose, otherwise its type label.
  Object formatEvent(Object? event) => printEventFullData
      ? (event ?? 'null')
      : safeBlocValueTypeLabel(
          event,
          captureMode: captureMode,
          resourceLimits: resourceLimits ?? DiagnosticResourceLimits.balanced,
        );

  /// Formats a state payload for display based on [printStateFullData].
  ///
  /// Returns the full object when verbose, otherwise its type label.
  Object formatState(Object? state) => printStateFullData
      ? (state ?? 'null')
      : safeBlocValueTypeLabel(
          state,
          captureMode: captureMode,
          resourceLimits: resourceLimits ?? DiagnosticResourceLimits.balanced,
        );

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
    bool? enableRedaction,
    RedactionService? redactor,
    DiagnosticCaptureMode? captureMode,
    DiagnosticResourceLimits? resourceLimits,
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
        enableRedaction: enableRedaction ?? this.enableRedaction,
        redactor: redactor ?? this.redactor,
        captureMode: captureMode ?? this.captureMode,
        resourceLimits: resourceLimits ?? this.resourceLimits,
      );
}

Map<String, dynamic> _prepareAdditionalData(
  Map<String, dynamic> data, {
  required bool enableRedaction,
  required RedactionService? redactor,
  required DiagnosticCaptureMode captureMode,
  required DiagnosticResourceLimits resourceLimits,
}) {
  final redactionActive = enableRedaction && ISpectRedaction.enabled;
  try {
    final prepared = LogExportOutput.boundJsonValue(
      data,
      preserveTypes: redactionActive,
      replaceOversizedStrings: redactionActive,
      allowCustomSerialization: captureMode == DiagnosticCaptureMode.balanced,
      allowCustomStringification: captureMode == DiagnosticCaptureMode.balanced,
      resourceLimits: resourceLimits,
    );
    final Object? output;
    if (redactionActive) {
      output = ISpectRedaction.resolveService(
        service: redactor,
      ).redactForExport(
        LogExportOutput.replaceTruncatedPrefixes(
          prepared,
          resourceLimits: resourceLimits,
        ),
        resourceLimits: resourceLimits,
      );
    } else {
      output = prepared;
    }
    final bounded = LogExportOutput.boundJsonValue(
      output,
      replaceOversizedStrings: redactionActive,
      resourceLimits: resourceLimits,
    );
    if (bounded is Map) {
      return <String, dynamic>{
        for (final entry in bounded.entries)
          if (entry.key case final String key) key: entry.value,
      };
    }
  } catch (_) {}
  return <String, dynamic>{};
}
