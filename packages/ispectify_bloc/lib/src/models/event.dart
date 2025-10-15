part of 'base.dart';

/// Log emitted when an event is added to a Bloc.
///
/// Corresponds to [BlocObserver.onEvent].
/// Triggered immediately when an event is added, before it is processed.
final class BlocEventLog extends BlocLifecycleLog {
  BlocEventLog({
    required Bloc<dynamic, dynamic> super.bloc,
    required this.event,
    required this.settings,
  }) : super(
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final payload = settings.printEventFullData
                ? event
                : event?.runtimeType ?? 'null';
            return '${bloc.runtimeType} received event'
                '\nEVENT: $payload';
          },
          additionalData: <String, dynamic>{
            if (event != null) 'event': event,
          },
        );

  final Object? event;
  final ISpectBlocSettings settings;

  static const String logKey = 'bloc-event';
}
