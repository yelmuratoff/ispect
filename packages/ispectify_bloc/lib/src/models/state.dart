import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/settings.dart';

class BlocStateLog extends ISpectifyData {
  BlocStateLog({
    required this.bloc,
    required this.transition,
    required this.settings,
  }) : super(
          key: getKey,
          '''${bloc.runtimeType} with event ${transition.event.runtimeType}\nCURRENT state: ${transition.currentState.runtimeType}\nNEXT state: ${transition.nextState.runtimeType}''',
          title: getKey,
        );

  final Bloc<dynamic, dynamic> bloc;
  final Transition<dynamic, dynamic> transition;
  final ISpectifyBlocSettings settings;

  static const getKey = 'bloc-state';
}
