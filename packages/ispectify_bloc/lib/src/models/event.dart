part of 'base.dart';

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
            return '${bloc.runtimeType} received event: $payload';
          },
          additionalData: <String, dynamic>{
            if (event != null) 'event': event,
          },
        );

  final Object? event;
  final ISpectBlocSettings settings;

  static const String logKey = 'bloc-event';
}
