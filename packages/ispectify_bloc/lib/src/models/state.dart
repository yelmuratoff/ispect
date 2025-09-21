import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/settings.dart';

class BlocStateLog extends ISpectifyData {
  BlocStateLog({
    required this.bloc,
    required this.change,
    required this.settings,
  }) : super(
          '''${bloc.runtimeType} changed\nCURRENT state: ${change.currentState.runtimeType}\nNEXT state: ${change.nextState.runtimeType}''',
          key: getKey,
          title: getKey,
        );

  final BlocBase<dynamic> bloc;
  final Change<dynamic> change;
  final ISpectBlocSettings settings;

  static const getKey = 'bloc-state';
}
