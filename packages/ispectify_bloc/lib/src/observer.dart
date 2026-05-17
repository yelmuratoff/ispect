import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
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

/// BLoC observer that logs lifecycle events via the unified trace API.
class ISpectBlocObserver extends BlocObserver {
  ISpectBlocObserver({
    ISpectLogger? logger,
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

  Map<String, Object?>? _applyMeta(Map<String, Object?>? meta) =>
      settings.isRedactionActive
          ? settings.redactAdditionalData(meta ?? {})
          : meta;

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

    final blocType = bloc.runtimeType.toString();
    final eventTypeName = event.runtimeType.toString();
    _logger.stateChange(
      source: 'bloc',
      operation: 'event',
      stateName: blocType,
      success: true,
      correlationId: eventId,
      consoleMessage: settings.printEventFullData && event != null
          ? '[bloc] event → $blocType\nEvent($eventTypeName): $event'
          : '[bloc] event → $blocType ($eventTypeName)',
      meta: _applyMeta({
        'blocType': blocType,
        'eventType': eventTypeName,
        if (settings.printEventFullData && event != null) 'event': event,
      }),
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
    final blocType = bloc.runtimeType.toString();
    final currentStateFormatted = settings.formatState(transition.currentState);
    final nextStateFormatted = settings.formatState(transition.nextState);
    final eventTypeName = transition.event.runtimeType.toString();
    _logger.stateChange(
      source: 'bloc',
      operation: 'transition',
      stateName: blocType,
      success: true,
      correlationId: eventId,
      consoleMessage: _buildBlocTransitionMessage(
        blocType: blocType,
        eventTypeName: eventTypeName,
        currentState: currentStateFormatted,
        nextState: nextStateFormatted,
        printEventFullData: settings.printEventFullData,
        event: transition.event,
      ),
      meta: _applyMeta({
        'blocType': blocType,
        'eventType': eventTypeName,
        'currentState': currentStateFormatted,
        'nextState': nextStateFormatted,
        if (settings.printEventFullData) 'event': transition.event,
      }),
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
    final blocType = bloc.runtimeType.toString();
    final currentStateFormatted = settings.formatState(change.currentState);
    final nextStateFormatted = settings.formatState(change.nextState);
    _logger.stateChange(
      source: 'bloc',
      operation: 'state',
      stateName: blocType,
      success: true,
      correlationId: eventId,
      consoleMessage: _buildBlocChangeMessage(
        blocType: blocType,
        currentState: currentStateFormatted,
        nextState: nextStateFormatted,
      ),
      meta: _applyMeta({
        'blocType': blocType,
        'currentState': currentStateFormatted,
        'nextState': nextStateFormatted,
      }),
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

    final blocType = bloc.runtimeType.toString();
    _logger.stateChange(
      source: 'bloc',
      operation: 'error',
      stateName: blocType,
      error: error,
      errorStackTrace: stackTrace,
      meta: _applyMeta({'blocType': blocType}),
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

    final blocType = bloc.runtimeType.toString();
    _logger.stateChange(
      source: 'bloc',
      operation: 'create',
      stateName: blocType,
      success: true,
      meta: _applyMeta({'blocType': blocType}),
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

    final blocType = bloc.runtimeType.toString();
    _logger.stateChange(
      source: 'bloc',
      operation: 'close',
      stateName: blocType,
      success: true,
      meta: _applyMeta({'blocType': blocType}),
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

    final blocType = bloc.runtimeType.toString();
    final eventTypeName = event?.runtimeType.toString();
    _logger.stateChange(
      source: 'bloc',
      operation: 'done',
      stateName: blocType,
      success: error == null,
      error: error,
      errorStackTrace: stackTrace,
      correlationId: eventId,
      consoleMessage: settings.printEventFullData && event != null
          ? '[bloc] done → $blocType\nEvent($eventTypeName): $event'
          : '[bloc] done → $blocType${eventTypeName != null ? ' ($eventTypeName)' : ''}',
      meta: _applyMeta({
        'blocType': blocType,
        if (event != null) 'eventType': eventTypeName,
        if (settings.printEventFullData && event != null) 'event': event,
        'hasError': error != null,
      }),
    );
  }

  static String _buildBlocTransitionMessage({
    required String blocType,
    required String eventTypeName,
    required Object currentState,
    required Object nextState,
    required bool printEventFullData,
    required Object? event,
  }) {
    final buf = StringBuffer('[bloc] transition → $blocType')
      ..write('\n$currentState → $nextState');
    if (printEventFullData && event != null) {
      buf.write('\nEvent($eventTypeName): $event');
    } else {
      buf.write(' ($eventTypeName)');
    }
    return buf.toString();
  }

  static String _buildBlocChangeMessage({
    required String blocType,
    required Object currentState,
    required Object nextState,
  }) =>
      '[bloc] state → $blocType\n$currentState → $nextState';
}
