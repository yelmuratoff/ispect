import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:ispectify_bloc/src/models/_models.dart';

/// `BLoC` logger on `ISpectify` base
///
/// `iSpectify` field is the current `ISpectify` instance.
/// Provide your instance if your application uses `ISpectify` as the default logger
/// Common ISpectify instance will be used by default
class ISpectifyBlocObserver extends BlocObserver {
  ISpectifyBlocObserver({
    ISpectify? iSpectify,
    this.settings = const ISpectifyBlocSettings(),
    this.onBlocEvent,
    this.onBlocTransition,
    this.onBlocChange,
    this.onBlocError,
    this.onBlocCreate,
    this.onBlocClose,
    this.filters = const [],
  }) {
    _iSpectify = iSpectify ?? ISpectify();
  }

  late ISpectify _iSpectify;
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
  final ISpectifyBlocSettings settings;
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
    _iSpectify.logCustom(
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
    _iSpectify.logCustom(
      BlocStateLog(
        bloc: bloc,
        transition: transition,
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
    _iSpectify.logCustom(
      BlocChangeLog(
        bloc: bloc,
        change: change,
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
    _iSpectify.error(
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
    _iSpectify.logCustom(BlocCreateLog(bloc: bloc));
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
    _iSpectify.logCustom(BlocCloseLog(bloc: bloc));
  }
}
