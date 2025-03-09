import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';

class BlocCreateLog extends ISpectifyData {
  BlocCreateLog({
    required this.bloc,
  }) : super(
          key: getKey,
          '${bloc.runtimeType} created',
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
