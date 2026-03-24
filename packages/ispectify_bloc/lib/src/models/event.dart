part of 'base.dart';

/// Log emitted when an event is added to a Bloc.
///
/// Corresponds to [BlocObserver.onEvent].
/// Triggered immediately when an event is added, before it is processed.
final class BlocEventLog extends BlocLifecycleLog {
  factory BlocEventLog({
    required Bloc<dynamic, dynamic> bloc,
    required Object? event,
    required ISpectBlocSettings settings,
  }) {
    final typeName = bloc.runtimeType.toString();
    return BlocEventLog._internal(
      bloc: bloc,
      event: event,
      settings: settings,
      typeName: typeName,
    );
  }

  BlocEventLog._internal({
    required Bloc<dynamic, dynamic> bloc,
    required this.event,
    required this.settings,
    required String typeName,
  }) : super(
          bloc: bloc,
          key: logKey,
          title: logKey,
          messageBuilder: () => '$typeName received event'
              '\nEVENT: ${settings.formatEvent(event)}',
          additionalData: settings.redactAdditionalData(<String, dynamic>{
            if (event != null) 'event': event,
          }),
        );

  final Object? event;
  final ISpectBlocSettings settings;

  static const String logKey = 'bloc-event';
}
