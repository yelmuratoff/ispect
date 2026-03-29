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

  void _trace({
    required String operation,
    required String blocType,
    bool? success,
    Object? error,
    StackTrace? errorStackTrace,
    Map<String, Object?>? meta,
    String? correlationId,
  }) {
    _logger.trace(
      category: stateCategory,
      source: 'bloc',
      operation: operation,
      target: blocType,
      success: success ?? (error == null),
      error: error,
      errorStackTrace: errorStackTrace,
      meta: settings.isRedactionActive
          ? settings.redactAdditionalData(meta ?? {})
          : meta,
      correlationId: correlationId,
    );
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

    final blocType = bloc.runtimeType.toString();
    _trace(
      operation: 'event',
      blocType: blocType,
      success: true,
      correlationId: eventId,
      meta: {
        'blocType': blocType,
        'eventType': event.runtimeType.toString(),
        if (settings.printEventFullData && event != null) 'event': event,
      },
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
    _trace(
      operation: 'transition',
      blocType: blocType,
      success: true,
      correlationId: eventId,
      meta: {
        'blocType': blocType,
        'eventType': transition.event.runtimeType.toString(),
        'currentState': settings.formatState(transition.currentState),
        'nextState': settings.formatState(transition.nextState),
        if (settings.printEventFullData) 'event': transition.event,
      },
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
    _trace(
      operation: 'state',
      blocType: blocType,
      success: true,
      correlationId: eventId,
      meta: {
        'blocType': blocType,
        'currentState': settings.formatState(change.currentState),
        'nextState': settings.formatState(change.nextState),
      },
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
    _trace(
      operation: 'error',
      blocType: blocType,
      error: error,
      errorStackTrace: stackTrace,
      meta: {'blocType': blocType},
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
    _trace(
      operation: 'create',
      blocType: blocType,
      success: true,
      meta: {'blocType': blocType},
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
    _trace(
      operation: 'close',
      blocType: blocType,
      success: true,
      meta: {'blocType': blocType},
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
    _trace(
      operation: 'done',
      blocType: blocType,
      success: error == null,
      error: error,
      errorStackTrace: stackTrace,
      correlationId: eventId,
      meta: {
        'blocType': blocType,
        if (event != null) 'eventType': event.runtimeType.toString(),
        if (settings.printEventFullData && event != null) 'event': event,
        'hasError': error != null,
      },
    );
  }
}
