import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';

class BlocCreateLog extends ISpectifyData {
  BlocCreateLog({
    required this.bloc,
  }) : super(
          '${bloc.runtimeType} created',
          key: getKey,
          title: getKey,
        );

  final BlocBase<dynamic> bloc;

  static const getKey = 'bloc-create';

  @override
  String get textMessage {
    final sb = StringBuffer()..write(message);
    return sb.toString();
  }
}
