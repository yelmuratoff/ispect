import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';

class BlocCloseLog extends ISpectifyData {
  BlocCloseLog({
    required this.bloc,
  }) : super(
          '${bloc.runtimeType} closed',
          key: getKey,
          title: getKey,
        );

  final BlocBase<dynamic> bloc;

  static const getKey = 'bloc-close';

  @override
  String get textMessage {
    final sb = StringBuffer()..write(message);
    return sb.toString();
  }
}
