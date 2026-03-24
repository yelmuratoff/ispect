import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/models/_models.dart';
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

/// `BLoC` logger on `ISpectLogger` base
///
/// `logger` field is the current `ISpectLogger` instance.
/// Provide your instance if your application uses `ISpectLogger` as the default logger
/// Common ISpectLogger instance will be used by default
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

  void _logUnhandledError(
    BlocBase<dynamic> bloc,
    Object error,
    StackTrace stackTrace,
  ) {
    try {
      onBlocError?.call(bloc, error, stackTrace);
    } catch (callbackError) {
      _logCallbackError('onBlocError', callbackError);
    }
    try {
      _logger.logData(
        BlocErrorLog(
          bloc: bloc,
          thrown: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (_) {
      // Prevent logging failure from propagating.
    }
  }

  /// Safely logs data, preventing logger exceptions from propagating into
  /// the Bloc framework.
  ///
  /// Delegates to [SafeLogExtension.safeLogData] from `ispectify`.
  void _safeLogData(ISpectLogData data) => _logger.safeLogData(data);

  /// Logs a warning when a user-provided callback throws.
  void _logCallbackError(String callbackName, Object error) {
    try {
      _logger.warning(
        'ISpectBlocObserver: $callbackName callback threw: $error',
      );
    } catch (_) {
      // Last resort — nothing we can do if the logger itself fails.
    }
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
    _safeLogData(
      BlocEventLog(
        bloc: bloc,
        event: event,
        settings: settings,
      ),
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
    _safeLogData(
      BlocTransitionLog(
        bloc: bloc,
        transition: transition,
        settings: settings,
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
    _safeLogData(
      BlocStateLog(
        bloc: bloc,
        change: change,
        settings: settings,
      ),
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!_shouldLog(toggle: settings.printErrors, candidate: error)) {
      return;
    }
    _logUnhandledError(bloc, error, stackTrace);
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
    _safeLogData(BlocCreateLog(bloc: bloc));
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
    _safeLogData(BlocCloseLog(bloc: bloc));
  }

  @override
  void onDone(
    Bloc<dynamic, dynamic> bloc,
    Object? event, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    super.onDone(bloc, event, error, stackTrace);
    final isEnabled = settings.enabled && !_isFiltered(bloc);
    if (!isEnabled) {
      return;
    }
    final shouldLogCompletion = (settings.printCompletions && error == null) ||
        (settings.printErrors && error != null);
    if (!shouldLogCompletion) {
      return;
    }
    _safeLogData(
      BlocDoneLog(
        bloc: bloc,
        settings: settings,
        event: event,
        hasError: error != null,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
