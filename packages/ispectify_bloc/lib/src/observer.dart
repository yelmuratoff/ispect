import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:ispectify_bloc/src/models/_models.dart';

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
    this.filters = const [],
  }) {
    _logger = logger ?? ISpectify();
  }

  late ISpectify _logger;
  final void Function(Bloc<dynamic, dynamic> bloc, Object? event)? onBlocEvent;
  final void Function(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  )? onBlocTransition;
  final void Function(BlocBase<dynamic> bloc, Change<dynamic> change)?
      onBlocChange;
  final void Function(
    BlocBase<dynamic> bloc,
    Object error,
    StackTrace stackTrace,
  )? onBlocError;
  final void Function(BlocBase<dynamic> bloc)? onBlocCreate;
  final void Function(BlocBase<dynamic> bloc)? onBlocClose;
  final ISpectBlocSettings settings;
  final List<String> filters;

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    final eventString = event.toString();
    final isFilterContains = filters.any(eventString.contains);
    if (!settings.enabled || !settings.printEvents || isFilterContains) {
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
    final transitionString = transition.toString();
    final isFilterContains = filters.any(transitionString.contains);
    if (!settings.enabled || !settings.printTransitions || isFilterContains) {
      return;
    }
    final accepted = settings.transitionFilter?.call(bloc, transition) ?? true;
    if (!accepted) {
      return;
    }
    onBlocTransition?.call(bloc, transition);
    _logger.logCustom(
      BlocChangeLog(
        bloc: bloc,
        change: Change(
          currentState: transition.currentState,
          nextState: transition.nextState,
        ),
        settings: settings,
      ),
    );
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    final changeString = change.toString();
    final isFilterContains = filters.any(changeString.contains);
    if (!settings.enabled || !settings.printChanges || isFilterContains) {
      return;
    }
    onBlocChange?.call(bloc, change);
    _logger.logCustom(
      BlocStateLog(
        bloc: bloc as Bloc<dynamic, dynamic>,
        transition: Transition(
          currentState: change.currentState,
          event: Object(),
          nextState: change.nextState,
        ),
        settings: settings,
      ),
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    final errorAsString = error.toString();
    final isFilterContains = filters.any(errorAsString.contains);
    if (!settings.enabled || isFilterContains) {
      return;
    }
    onBlocError?.call(bloc, error, stackTrace);
    _logger.error(
      '${bloc.runtimeType}',
      exception: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    final blocAsString = bloc.toString();
    final isFilterContains = filters.any(blocAsString.contains);
    if (!settings.enabled || !settings.printCreations || isFilterContains) {
      return;
    }
    onBlocCreate?.call(bloc);
    _logger.logCustom(BlocCreateLog(bloc: bloc));
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    final blocAsString = bloc.toString();
    final isFilterContains = filters.any(blocAsString.contains);
    if (!settings.enabled || !settings.printClosings || isFilterContains) {
      return;
    }
    onBlocClose?.call(bloc);
    _logger.logCustom(BlocCloseLog(bloc: bloc));
  }
}
