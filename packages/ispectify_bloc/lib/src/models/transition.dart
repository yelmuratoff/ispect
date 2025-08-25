import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/settings.dart';

class BlocChangeLog extends ISpectifyData {
  BlocChangeLog({
    required this.bloc,
    required this.change,
    required this.settings,
  }) : super(
          key: getKey,
          '''${bloc.runtimeType} changed\nCURRENT state: ${change.currentState.runtimeType}\nNEXT state: ${change.nextState.runtimeType}''',
          title: getKey,
        );

  final BlocBase<dynamic> bloc;
  final Change<dynamic> change;
  final ISpectBlocSettings settings;

  static const getKey = 'bloc-transition';
}
