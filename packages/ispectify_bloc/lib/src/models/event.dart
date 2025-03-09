import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/settings.dart';

class BlocEventLog extends ISpectifyData {
  BlocEventLog({
    required this.bloc,
    required this.event,
    required this.settings,
  }) : super(
          key: getKey,
          settings.printEventFullData
              ? '${bloc.runtimeType} receive event:\n$event'
              : '${bloc.runtimeType} receive event: ${event.runtimeType}',
          title: getKey,
        );

  final Bloc<dynamic, dynamic> bloc;
  final Object? event;
  final ISpectifyBlocSettings settings;

  static const getKey = 'bloc-event';

  @override
  String get textMessage {
    final sb = StringBuffer()..write(message);
    return sb.toString();
  }
}
