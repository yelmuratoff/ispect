import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

/// `BLoC` logger on `Talker` base
///
/// `talker` field is the current `Talker` instance.
/// Provide your instance if your application uses `Talker` as the default logger
/// Common Talker instance will be used by default
class TalkerBlocObserver extends BlocObserver {
  TalkerBlocObserver({
    Talker? talker,
    this.settings = const TalkerBlocLoggerSettings(),
    this.onBlocEvent,
    this.onBlocTransition,
    this.onBlocChange,
    this.onBlocError,
    this.onBlocCreate,
    this.onBlocClose,
  }) {
    _talker = talker ?? Talker();
  }

  late Talker _talker;
  final void Function()? onBlocEvent;
  final void Function()? onBlocTransition;
  final void Function()? onBlocChange;
  final void Function()? onBlocError;
  final void Function()? onBlocCreate;
  final void Function()? onBlocClose;
  final TalkerBlocLoggerSettings settings;

  @override
  @mustCallSuper
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!settings.enabled || !settings.printEvents) {
      return;
    }
    final accepted = settings.eventFilter?.call(bloc, event) ?? true;
    if (!accepted) {
      return;
    }
    onBlocEvent?.call();
    _talker.logTyped(
      BlocEventLog(
        bloc: bloc,
        event: event,
        settings: settings,
      ),
    );
  }

  @override
  @mustCallSuper
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (!settings.enabled || !settings.printTransitions) {
      return;
    }
    final accepted = settings.transitionFilter?.call(bloc, transition) ?? true;
    if (!accepted) {
      return;
    }
    onBlocTransition?.call();
    _talker.logTyped(
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
    if (!settings.enabled || !settings.printChanges) {
      return;
    }
    onBlocChange?.call();
    _talker.logTyped(
      BlocChangeLog(
        bloc: bloc,
        change: change,
        settings: settings,
      ),
    );
  }

  @override
  @mustCallSuper
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    onBlocError?.call();
    _talker.error('${bloc.runtimeType}', error, stackTrace);
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (!settings.enabled || !settings.printCreations) {
      return;
    }
    onBlocCreate?.call();
    _talker.logTyped(BlocCreateLog(bloc: bloc));
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (!settings.enabled || !settings.printClosings) {
      return;
    }
    onBlocClose?.call();
    _talker.logTyped(BlocCloseLog(bloc: bloc));
  }
}
