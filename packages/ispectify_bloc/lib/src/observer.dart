import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/_data.dart';
import 'package:ispectify_bloc/src/safe_type_label.dart';
import 'package:ispectify_bloc/src/settings.dart';
import 'package:meta/meta.dart';

typedef BlocEventCallback = void Function(
  Bloc<dynamic, dynamic> bloc,
  Object? event,
);

typedef BlocTransitionCallback = void Function(
  Bloc<dynamic, dynamic> bloc,
  Transition<dynamic, dynamic> transition,
);

typedef BlocChangeCallback = void Function(
  BlocBase<dynamic> bloc,
  Change<dynamic> change,
);

typedef BlocErrorCallback = void Function(
  BlocBase<dynamic> bloc,
  Object error,
  StackTrace stackTrace,
);

typedef BlocLifecycleCallback = void Function(BlocBase<dynamic> bloc);

typedef BlocFilterPredicate = bool Function(Object? candidate);

/// BLoC observer that logs lifecycle events via the unified trace API under
/// the `bloc-event`, `bloc-transition`, `bloc-state`, `bloc-create`,
/// `bloc-close`, `bloc-done`, and `bloc-error` log keys.
class ISpectBlocObserver extends BlocObserver {
  ISpectBlocObserver({
    ISpectLogger? logger,
    this.settings = ISpectBlocSettings.verbose,
    this.onBlocEvent,
    this.onBlocTransition,
    this.onBlocChange,
    this.onBlocError,
    this.onBlocCreate,
    this.onBlocClose,
    Iterable<Pattern> filters = const <Pattern>[],
    this.filterPredicate,
  }) : filters = List<Pattern>.unmodifiable(filters) {
    _logger = logger ?? ISpectLogger();
    settings.resourceLimits?.validate();
  }

  late final ISpectLogger _logger;
  final BlocEventCallback? onBlocEvent;
  final BlocTransitionCallback? onBlocTransition;
  final BlocChangeCallback? onBlocChange;
  final BlocErrorCallback? onBlocError;
  final BlocLifecycleCallback? onBlocCreate;
  final BlocLifecycleCallback? onBlocClose;
  final ISpectBlocSettings settings;
  final List<Pattern> filters;
  final BlocFilterPredicate? filterPredicate;

  static const String _source = 'bloc';

  /// Test-only override for the compile-time [kISpectEnabled] gate.
  ///
  /// This can only narrow the compile-time gate; it can never enable ISpect
  /// when the build omitted `ISPECT_ENABLED`.
  @visibleForTesting
  static bool? debugEnabledOverride;

  bool get _ispectEnabled => kISpectEnabled && (debugEnabledOverride ?? true);
  bool get _loggingEnabled =>
      _ispectEnabled && _logger.isEnabled && settings.enabled;
  bool get _captureEnabled => _loggingEnabled && _logger.hasActiveConsumers;

  static final _pendingEvents =
      Expando<_PendingEventCorrelations>('bloc_event_ids');

  DiagnosticResourceLimits get _resourceLimits =>
      settings.resourceLimits ?? _logger.options.resourceLimits;

  bool _isFiltered(Object? candidate) {
    final predicateMatch = filterPredicate?.call(candidate) ?? false;
    if (!_loggingEnabled) {
      return true;
    }
    if (predicateMatch) {
      return true;
    }
    if (filters.isEmpty) {
      return false;
    }
    final candidateString = _filterText(candidate);
    if (candidateString.isEmpty) {
      return false;
    }
    for (final pattern in filters) {
      var matches = false;
      try {
        matches = candidateString.contains(pattern);
      } catch (_) {}
      if (!_loggingEnabled) return true;
      if (matches) return true;
    }
    return false;
  }

  String _filterText(Object? candidate) {
    final value = switch (candidate) {
      null => '',
      final String value => value,
      final BlocBase<dynamic> bloc => safeBlocTypeLabel(
          bloc,
          captureMode: settings.captureMode,
          resourceLimits: _resourceLimits,
        ),
      _ => LogExportOutput.boundJsonValue(
          candidate,
          resourceLimits: _resourceLimits,
          allowCustomSerialization:
              settings.captureMode == DiagnosticCaptureMode.balanced,
          allowCustomStringification:
              settings.captureMode == DiagnosticCaptureMode.balanced,
        ),
    };
    final text = switch (value) {
      final String value => value,
      final num value => value.toString(),
      final bool value => value.toString(),
      _ => JsonValueNormalizer.unprintableValue,
    };
    return LogExportOutput.truncateUtf8(
      text,
      maxBytes: _resourceLimits.maxStateTraceBytes,
    );
  }

  bool _shouldLog({
    required bool toggle,
    required Object? candidate,
    bool hasAdapterCallback = false,
  }) {
    if (!_loggingEnabled || !toggle) {
      return false;
    }
    if (!_captureEnabled && !hasAdapterCallback) {
      return false;
    }
    final filtered = _isFiltered(candidate);
    return _loggingEnabled && !filtered;
  }

  void _logCallbackError(String callbackName, Object _) {
    try {
      _logger.warning(
        'ISpectBlocObserver: $callbackName callback threw safely.',
      );
    } catch (_) {}
  }

  RedactionService? get _redactor => settings.isRedactionActive
      ? ISpectRedaction.resolveService(service: settings.redactor)
      : null;
  // Every caller-controlled trace field is prepared below. A second generic
  // pass would replace the configured redactor and repeat boundary traversal.
  ISpectTraceConfig get _traceConfig => ISpectTraceConfig(
        redact: false,
        attachStackOnError: true,
        resourceLimits: _resourceLimits,
      );

  bool get _redactionActive => settings.isRedactionActive;

  Object? _prepareTraceValue(Object? value) {
    final redactor = _redactor;
    final redactionActive = _redactionActive;
    final prepared = LogExportOutput.boundJsonValue(
      value,
      maxBytes: _resourceLimits.maxStateTraceBytes,
      resourceLimits: _resourceLimits,
      preserveTypes: redactionActive,
      replaceOversizedStrings: redactionActive,
      allowCustomSerialization:
          settings.captureMode == DiagnosticCaptureMode.balanced,
      allowCustomStringification:
          settings.captureMode == DiagnosticCaptureMode.balanced,
    );
    if (!redactionActive) return prepared;
    try {
      final redacted = redactor!.redactForExport(
        LogExportOutput.replaceTruncatedPrefixes(
          prepared,
          resourceLimits: _resourceLimits,
        ),
        resourceLimits: _resourceLimits,
      );
      return LogExportOutput.boundJsonValue(
        redacted,
        maxBytes: _resourceLimits.maxStateTraceBytes,
        resourceLimits: _resourceLimits,
        replaceOversizedStrings: true,
      );
    } catch (_) {
      return '[REDACTED]';
    }
  }

  String _prepareTraceText(Object? value) {
    final prepared = _prepareTraceValue(value);
    return switch (prepared) {
      final String value => value,
      final num value => value.toString(),
      final bool value => value.toString(),
      _ => '[REDACTED]',
    };
  }

  String? _prepareTraceError(Object? error) {
    if (error == null) return null;
    return _prepareTraceText(error);
  }

  StackTrace? _prepareTraceStack(StackTrace? stackTrace) {
    if (stackTrace == null) return null;
    return StackTrace.fromString(_prepareTraceText(stackTrace));
  }

  Map<String, Object?> _prepareTraceMeta(Map<String, dynamic> data) {
    final prepared = _prepareTraceValue(data);
    if (prepared is Map) {
      final result = <String, Object?>{};
      for (final entry in prepared.entries) {
        if (entry.key case final String key) {
          result[key] = entry.value;
        }
      }
      return result;
    }
    return <String, Object?>{};
  }

  String _traceTarget(
    Map<String, Object?> meta,
    String key,
    String fallback,
  ) {
    final value = meta[key];
    if (value is String) return value;
    return _redactionActive ? '[REDACTED]' : _prepareTraceText(fallback);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!_loggingEnabled || !settings.printEvents) {
      return;
    }
    if (!_captureEnabled && onBlocEvent == null) {
      return;
    }
    var correlations = _captureEnabled
        ? _pendingEvents[bloc] ??= _PendingEventCorrelations(
            capacity: _resourceLimits.maxPendingCorrelations,
          )
        : null;
    final filtered = _isFiltered(bloc);
    if (!_loggingEnabled) {
      return;
    }
    if (filtered) {
      if (_captureEnabled) correlations?.add(event, null);
      return;
    }
    final accepted = settings.eventFilter?.call(bloc, event) ?? true;
    if (!_loggingEnabled) {
      return;
    }
    if (!accepted) {
      if (_captureEnabled) correlations?.add(event, null);
      return;
    }
    try {
      onBlocEvent?.call(bloc, event);
    } catch (callbackError) {
      _logCallbackError('onBlocEvent', callbackError);
    }
    if (!_loggingEnabled) {
      return;
    }

    if (!_captureEnabled) {
      return;
    }
    correlations ??= _pendingEvents[bloc] ??= _PendingEventCorrelations(
      capacity: _resourceLimits.maxPendingCorrelations,
    );
    final eventId = generateTraceId();
    correlations.add(event, eventId);

    final data = BlocEventData(
      bloc: bloc,
      event: event,
      includeFullData: settings.printEventFullData,
      captureMode: settings.captureMode,
      resourceLimits: _resourceLimits,
    );
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(meta, BlocJsonKeys.blocType, data.blocType);
    final redactedEvent = meta[BlocJsonKeys.event];
    _logger.blocEvent(
      source: _source,
      target: target,
      correlationId: eventId,
      meta: meta,
      config: _traceConfig,
      consoleMessage: _prepareTraceText(
        redactedEvent != null
            ? 'event → $target\n'
                'Event(${data.eventType}): $redactedEvent'
            : 'event → $target (${data.eventType})',
      ),
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    final correlations = _pendingEvents[bloc];
    final eventId = correlations?.correlationIdFor(transition.event);
    try {
      if (!_shouldLog(
        toggle: settings.printTransitions,
        candidate: bloc,
        hasAdapterCallback: onBlocTransition != null,
      )) {
        return;
      }
      final accepted =
          settings.transitionFilter?.call(bloc, transition) ?? true;
      if (!_loggingEnabled) {
        return;
      }
      if (!accepted) {
        return;
      }
      try {
        onBlocTransition?.call(bloc, transition);
      } catch (callbackError) {
        _logCallbackError('onBlocTransition', callbackError);
      }
      if (!_captureEnabled) {
        return;
      }

      final data = BlocTransitionData(
        bloc: bloc,
        transition: transition,
        includeEventFullData: settings.printEventFullData,
        formattedCurrentState: settings.formatState(transition.currentState),
        formattedNextState: settings.formatState(transition.nextState),
        captureMode: settings.captureMode,
        resourceLimits: _resourceLimits,
      );
      final meta = _prepareTraceMeta(data.toJson());
      final target = _traceTarget(meta, BlocJsonKeys.blocType, data.blocType);
      _logger.blocTransition(
        source: _source,
        target: target,
        correlationId: eventId,
        meta: meta,
        config: _traceConfig,
        consoleMessage: _prepareTraceText(
          _buildBlocTransitionMessage(
            blocType: target,
            eventTypeName: data.eventType,
            currentState: meta[BlocJsonKeys.currentState],
            nextState: meta[BlocJsonKeys.nextState],
            event: meta[BlocJsonKeys.event],
          ),
        ),
      );
    } finally {
      correlations?.nextChangeCorrelationId = _loggingEnabled ? eventId : null;
    }
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    final eventId = _pendingEvents[bloc]?.takeNextChangeCorrelationId();
    if (!_shouldLog(
      toggle: settings.printChanges,
      candidate: bloc,
      hasAdapterCallback: onBlocChange != null,
    )) {
      return;
    }
    final accepted = settings.changeFilter?.call(bloc, change) ?? true;
    if (!_loggingEnabled) {
      return;
    }
    if (!accepted) {
      return;
    }
    try {
      onBlocChange?.call(bloc, change);
    } catch (callbackError) {
      _logCallbackError('onBlocChange', callbackError);
    }
    if (!_captureEnabled) {
      return;
    }

    final data = BlocChangeData(
      bloc: bloc,
      change: change,
      formattedCurrentState: settings.formatState(change.currentState),
      formattedNextState: settings.formatState(change.nextState),
      captureMode: settings.captureMode,
      resourceLimits: _resourceLimits,
    );
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(meta, BlocJsonKeys.blocType, data.blocType);
    _logger.blocState(
      source: _source,
      target: target,
      correlationId: eventId,
      meta: meta,
      config: _traceConfig,
      consoleMessage: _prepareTraceText(
        _buildBlocChangeMessage(
          blocType: target,
          currentState: meta[BlocJsonKeys.currentState],
          nextState: meta[BlocJsonKeys.nextState],
        ),
      ),
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!_shouldLog(
      toggle: settings.printErrors,
      candidate: bloc,
      hasAdapterCallback: onBlocError != null,
    )) {
      return;
    }
    try {
      onBlocError?.call(bloc, error, stackTrace);
    } catch (callbackError) {
      _logCallbackError('onBlocError', callbackError);
    }
    if (!_captureEnabled) {
      return;
    }

    final data = BlocErrorData(
      bloc: bloc,
      error: error,
      stackTrace: stackTrace,
      captureMode: settings.captureMode,
      resourceLimits: _resourceLimits,
    );
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(meta, BlocJsonKeys.blocType, data.blocType);
    _logger.blocError(
      source: _source,
      target: target,
      error: _prepareTraceError(error)!,
      errorStackTrace: _prepareTraceStack(stackTrace),
      meta: meta,
      config: _traceConfig,
    );
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (!_shouldLog(
      toggle: settings.printCreations,
      candidate: bloc,
      hasAdapterCallback: onBlocCreate != null,
    )) {
      return;
    }
    try {
      onBlocCreate?.call(bloc);
    } catch (callbackError) {
      _logCallbackError('onBlocCreate', callbackError);
    }
    if (!_captureEnabled) {
      return;
    }

    final data = BlocLifecycleData(
      bloc: bloc,
      captureMode: settings.captureMode,
      resourceLimits: _resourceLimits,
    );
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(meta, BlocJsonKeys.blocType, data.blocType);
    _logger.blocCreate(
      source: _source,
      target: target,
      meta: meta,
      config: _traceConfig,
    );
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _pendingEvents[bloc] = null;
    if (!_shouldLog(
      toggle: settings.printClosings,
      candidate: bloc,
      hasAdapterCallback: onBlocClose != null,
    )) {
      return;
    }
    try {
      onBlocClose?.call(bloc);
    } catch (callbackError) {
      _logCallbackError('onBlocClose', callbackError);
    }
    if (!_captureEnabled) {
      return;
    }

    final data = BlocLifecycleData(
      bloc: bloc,
      captureMode: settings.captureMode,
      resourceLimits: _resourceLimits,
    );
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(meta, BlocJsonKeys.blocType, data.blocType);
    _logger.blocClose(
      source: _source,
      target: target,
      meta: meta,
      config: _traceConfig,
    );
  }

  @override
  void onDone(
    Bloc<dynamic, dynamic> bloc,
    Object? event, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    super.onDone(bloc, event, error, stackTrace);

    final eventId = _pendingEvents[bloc]?.remove(event);

    if (!_captureEnabled) return;
    final filtered = _isFiltered(bloc);
    if (!_captureEnabled || filtered) return;

    final shouldLogCompletion = (settings.printCompletions && error == null) ||
        (settings.printErrors && error != null);
    if (!shouldLogCompletion) return;

    final data = BlocDoneData(
      bloc: bloc,
      event: event,
      hasError: error != null,
      includeFullData: settings.printEventFullData,
      captureMode: settings.captureMode,
      resourceLimits: _resourceLimits,
    );
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(meta, BlocJsonKeys.blocType, data.blocType);
    final redactedEvent = meta[BlocJsonKeys.event];
    _logger.blocDone(
      source: _source,
      target: target,
      hasError: data.hasError,
      error: _prepareTraceError(error),
      errorStackTrace: _prepareTraceStack(stackTrace),
      correlationId: eventId,
      meta: meta,
      config: _traceConfig,
      consoleMessage: _prepareTraceText(
        redactedEvent != null
            ? 'done → $target\n'
                'Event(${data.eventType}): $redactedEvent'
            : 'done → $target'
                '${data.eventType != null ? ' (${data.eventType})' : ''}',
      ),
    );
  }

  static String _buildBlocTransitionMessage({
    required String blocType,
    required String eventTypeName,
    required Object? currentState,
    required Object? nextState,
    required Object? event,
  }) {
    final buf = StringBuffer('transition → $blocType')
      ..write('\n$currentState → $nextState');
    if (event != null) {
      buf.write('\nEvent($eventTypeName): $event');
    } else {
      buf.write(' ($eventTypeName)');
    }
    return buf.toString();
  }

  static String _buildBlocChangeMessage({
    required String blocType,
    required Object? currentState,
    required Object? nextState,
  }) =>
      'state → $blocType\n$currentState → $nextState';
}

final class _PendingEventCorrelations {
  _PendingEventCorrelations({required this.capacity});

  final int capacity;
  final Map<Object?, _PendingEventCorrelation> _events =
      HashMap<Object?, _PendingEventCorrelation>.identity();
  var _overflowCount = 0;
  String? nextChangeCorrelationId;

  void add(Object? event, String? correlationId) {
    final pending = _events[event];
    if (pending != null) {
      pending.addDuplicate();
      return;
    }
    if (_overflowCount > 0 || _events.length >= capacity) {
      _overflowCount++;
      return;
    }
    _events[event] = _PendingEventCorrelation(correlationId);
  }

  String? correlationIdFor(Object? event) => _events[event]?.correlationId;

  String? takeNextChangeCorrelationId() {
    final correlationId = nextChangeCorrelationId;
    nextChangeCorrelationId = null;
    return correlationId;
  }

  String? remove(Object? event) {
    final pending = _events[event];
    if (pending != null) {
      final correlationId = pending.correlationId;
      if (pending.removeOne()) {
        _events.remove(event);
      }
      return correlationId;
    }
    if (_overflowCount > 0) {
      _overflowCount--;
    }
    return null;
  }
}

final class _PendingEventCorrelation {
  _PendingEventCorrelation(this._correlationId);

  String? _correlationId;
  var _pendingCount = 1;
  var _isAmbiguous = false;

  String? get correlationId =>
      _pendingCount == 1 && !_isAmbiguous ? _correlationId : null;

  void addDuplicate() {
    _pendingCount++;
    _isAmbiguous = true;
    _correlationId = null;
  }

  bool removeOne() {
    _pendingCount--;
    return _pendingCount == 0;
  }
}
