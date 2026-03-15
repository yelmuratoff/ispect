part of 'base.dart';

/// Log emitted when an event is added to a Bloc.
///
/// Corresponds to [BlocObserver.onEvent].
/// Triggered immediately when an event is added, before it is processed.
final class BlocEventLog extends BlocLifecycleLog {
  BlocEventLog({
    required Bloc<dynamic, dynamic> bloc,
    required this.event,
    required this.settings,
  }) : super(
          bloc: bloc,
          key: logKey,
          title: logKey,
          messageBuilder: () {
            final blocType = bloc.runtimeType;
            final payload = settings.printEventFullData
                ? event
                : event?.runtimeType ?? 'null';
            return '$blocType received event'
                '\nEVENT: $payload';
          },
          additionalData: settings.redactAdditionalData(<String, dynamic>{
            if (event != null) 'event': event,
          }),
        );

  final Object? event;
  final ISpectBlocSettings settings;

  static const String logKey = 'bloc-event';
}
