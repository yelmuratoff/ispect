import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/_data.dart';
import 'package:ispectify_bloc/src/settings.dart';

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
    // ignore: use_named_constants — the matching named const is deprecated.
    this.settings = const ISpectBlocSettings(),
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

  /// Event correlation: stores pending eventIds per bloc instance.
  /// Queue (FIFO) handles concurrent events correctly.
  /// Expando is GC-safe — cleaned when Bloc is destroyed.
  static final _pendingEventIds = Expando<Queue<String>>('bloc_event_ids');

  bool _isFiltered(Object? candidate) {
    if (filterPredicate?.call(candidate) ?? false) {
      return true;
    }
    if (filters.isEmpty) {
      return false;
    }
    final candidateString = switch (candidate) {
      final String value => value,
      final BlocBase<dynamic> bloc => bloc.runtimeType.toString(),
      final Type type => type.toString(),
      _ => candidate?.toString() ?? '',
    };
    if (candidateString.isEmpty) {
      return false;
    }
    for (final pattern in filters) {
      if (candidateString.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  bool _shouldLog({
    required bool toggle,
    required Object? candidate,
  }) {
    if (!settings.enabled || !toggle) {
      return false;
    }
    return !_isFiltered(candidate);
  }

  void _logCallbackError(String callbackName, Object error) {
    try {
      _logger.warning(
        'ISpectBlocObserver: $callbackName callback threw: $error',
      );
    } catch (_) {}
  }

  /// Defaults to a [RedactionService] when redaction is enabled but no explicit
  /// redactor was supplied, so sensitive payloads are masked out of the box —
  /// matching the network/DB interceptors. `null` only when redaction is off.
  late final RedactionService? _redactor = settings.enableRedaction
      ? (settings.redactor ?? RedactionService())
      : null;

  Map<String, Object?> _withRedaction(
    Map<String, dynamic> data,
    void Function(Map<String, dynamic>, RedactionService) redact,
  ) {
    final redactor = _redactor;
    if (redactor != null) {
      redact(data, redactor);
    }
    return data;
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!_shouldLog(toggle: settings.printEvents, candidate: bloc)) {
      return;
    }
    final accepted = settings.eventFilter?.call(bloc, event) ?? true;
    if (!accepted) {
      return;
    }
    try {
      onBlocEvent?.call(bloc, event);
    } catch (callbackError) {
      _logCallbackError('onBlocEvent', callbackError);
    }

    final eventId = generateTraceId();
    (_pendingEventIds[bloc] ??= Queue<String>()).add(eventId);

    final data = BlocEventData(
      bloc: bloc,
      event: event,
      includeFullData: settings.printEventFullData,
    );
    final meta = _withRedaction(data.toJson(), BlocEventData.redact);
    final redactedEvent = meta[BlocJsonKeys.event];
    _logger.blocEvent(
      source: _source,
      target: data.blocType,
      correlationId: eventId,
      meta: meta,
      consoleMessage: redactedEvent != null
          ? '[bloc] event → ${data.blocType}\nEvent(${data.eventType}): $redactedEvent'
          : '[bloc] event → ${data.blocType} (${data.eventType})',
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (!_shouldLog(toggle: settings.printTransitions, candidate: bloc)) {
      return;
    }
    final accepted = settings.transitionFilter?.call(bloc, transition) ?? true;
    if (!accepted) {
      return;
    }
    try {
      onBlocTransition?.call(bloc, transition);
    } catch (callbackError) {
      _logCallbackError('onBlocTransition', callbackError);
    }

    final eventId = _pendingEventIds[bloc]?.firstOrNull;
    final data = BlocTransitionData(
      bloc: bloc,
      transition: transition,
      includeEventFullData: settings.printEventFullData,
      formattedCurrentState: settings.formatState(transition.currentState),
      formattedNextState: settings.formatState(transition.nextState),
    );
    final meta = _withRedaction(data.toJson(), BlocTransitionData.redact);
    _logger.blocTransition(
      source: _source,
      target: data.blocType,
      correlationId: eventId,
      meta: meta,
      consoleMessage: _buildBlocTransitionMessage(
        blocType: data.blocType,
        eventTypeName: data.eventType,
        currentState: meta[BlocJsonKeys.currentState],
        nextState: meta[BlocJsonKeys.nextState],
        event: meta[BlocJsonKeys.event],
      ),
    );
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (!_shouldLog(toggle: settings.printChanges, candidate: bloc)) {
      return;
    }
    final accepted = settings.changeFilter?.call(bloc, change) ?? true;
    if (!accepted) {
      return;
    }
    try {
      onBlocChange?.call(bloc, change);
    } catch (callbackError) {
      _logCallbackError('onBlocChange', callbackError);
    }

    // Peek eventId (no pop — pop happens only in onDone)
    final eventId = _pendingEventIds[bloc]?.firstOrNull;
    final data = BlocChangeData(
      bloc: bloc,
      change: change,
      formattedCurrentState: settings.formatState(change.currentState),
      formattedNextState: settings.formatState(change.nextState),
    );
    final meta = _withRedaction(data.toJson(), BlocChangeData.redact);
    _logger.blocState(
      source: _source,
      target: data.blocType,
      correlationId: eventId,
      meta: meta,
      consoleMessage: _buildBlocChangeMessage(
        blocType: data.blocType,
        currentState: meta[BlocJsonKeys.currentState],
        nextState: meta[BlocJsonKeys.nextState],
      ),
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!_shouldLog(toggle: settings.printErrors, candidate: error)) {
      return;
    }
    try {
      onBlocError?.call(bloc, error, stackTrace);
    } catch (callbackError) {
      _logCallbackError('onBlocError', callbackError);
    }

    final data = BlocErrorData(
      bloc: bloc,
      error: error,
      stackTrace: stackTrace,
    );
    final meta = _withRedaction(data.toJson(), BlocErrorData.redact);
    _logger.blocError(
      source: _source,
      target: data.blocType,
      error: error,
      errorStackTrace: stackTrace,
      meta: meta,
    );
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (!_shouldLog(toggle: settings.printCreations, candidate: bloc)) {
      return;
    }
    try {
      onBlocCreate?.call(bloc);
    } catch (callbackError) {
      _logCallbackError('onBlocCreate', callbackError);
    }

    final data = BlocLifecycleData(bloc: bloc);
    final meta = _withRedaction(data.toJson(), BlocLifecycleData.redact);
    _logger.blocCreate(
      source: _source,
      target: data.blocType,
      meta: meta,
    );
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (!_shouldLog(toggle: settings.printClosings, candidate: bloc)) {
      return;
    }
    try {
      onBlocClose?.call(bloc);
    } catch (callbackError) {
      _logCallbackError('onBlocClose', callbackError);
    }

    final data = BlocLifecycleData(bloc: bloc);
    final meta = _withRedaction(data.toJson(), BlocLifecycleData.redact);
    _logger.blocClose(
      source: _source,
      target: data.blocType,
      meta: meta,
    );

    // Clear any pending event IDs for this bloc to prevent memory leaks.
    _pendingEventIds[bloc] = null;
  }

  @override
  void onDone(
    Bloc<dynamic, dynamic> bloc,
    Object? event, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    super.onDone(bloc, event, error, stackTrace);

    // Pop eventId BEFORE any early returns to prevent memory leaks.
    final queue = _pendingEventIds[bloc];
    final eventId = queue?.firstOrNull;
    if (queue != null && queue.isNotEmpty) queue.removeFirst();

    final isEnabled = settings.enabled && !_isFiltered(bloc);
    if (!isEnabled) return;

    final shouldLogCompletion = (settings.printCompletions && error == null) ||
        (settings.printErrors && error != null);
    if (!shouldLogCompletion) return;

    final data = BlocDoneData(
      bloc: bloc,
      event: event,
      hasError: error != null,
      includeFullData: settings.printEventFullData,
    );
    final meta = _withRedaction(data.toJson(), BlocDoneData.redact);
    final redactedEvent = meta[BlocJsonKeys.event];
    _logger.blocDone(
      source: _source,
      target: data.blocType,
      hasError: data.hasError,
      error: error,
      errorStackTrace: stackTrace,
      correlationId: eventId,
      meta: meta,
      consoleMessage: redactedEvent != null
          ? '[bloc] done → ${data.blocType}\nEvent(${data.eventType}): $redactedEvent'
          : '[bloc] done → ${data.blocType}${data.eventType != null ? ' (${data.eventType})' : ''}',
    );
  }

  static String _buildBlocTransitionMessage({
    required String blocType,
    required String eventTypeName,
    required Object? currentState,
    required Object? nextState,
    required Object? event,
  }) {
    final buf = StringBuffer('[bloc] transition → $blocType')
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
      '[bloc] state → $blocType\n$currentState → $nextState';
}
