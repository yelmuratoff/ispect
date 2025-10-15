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

/// `BLoC` logger on `ISpectify` base
///
/// `logger` field is the current `ISpectify` instance.
/// Provide your instance if your application uses `ISpectify` as the default logger
/// Common ISpectify instance will be used by default
class ISpectBlocObserver extends BlocObserver {
  ISpectBlocObserver({
    ISpectify? logger,
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
    _logger = logger ?? ISpectify();
  }

  late final ISpectify _logger;
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
    onBlocError?.call(bloc, error, stackTrace);
    _logger.logCustom(
      BlocErrorLog(
        bloc: bloc,
        thrown: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!_shouldLog(toggle: settings.printEvents, candidate: event)) {
      return;
    }
    final accepted = settings.eventFilter?.call(bloc, event) ?? true;
    if (!accepted) {
      return;
    }
    onBlocEvent?.call(bloc, event);
    _logger.logCustom(
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
    if (!_shouldLog(toggle: settings.printTransitions, candidate: transition)) {
      return;
    }
    final accepted = settings.transitionFilter?.call(bloc, transition) ?? true;
    if (!accepted) {
      return;
    }
    onBlocTransition?.call(bloc, transition);
    _logger.logCustom(
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
    if (!_shouldLog(toggle: settings.printChanges, candidate: change)) {
      return;
    }
    final accepted = settings.changeFilter?.call(bloc, change) ?? true;
    if (!accepted) {
      return;
    }
    onBlocChange?.call(bloc, change);
    _logger.logCustom(
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
    onBlocCreate?.call(bloc);
    _logger.logCustom(BlocCreateLog(bloc: bloc));
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (!_shouldLog(toggle: settings.printClosings, candidate: bloc)) {
      return;
    }
    onBlocClose?.call(bloc);
    _logger.logCustom(BlocCloseLog(bloc: bloc));
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
    if (!settings.printCompletions || error != null) {
      return;
    }
    _logger.logCustom(
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
