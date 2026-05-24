import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/bloc_json_keys.dart';

/// Snapshot of a BLoC / Cubit `onChange` invocation.
class BlocChangeData {
  BlocChangeData({
    required this.bloc,
    required this.change,
    required this.formattedCurrentState,
    required this.formattedNextState,
  });

  final BlocBase<dynamic> bloc;
  final Change<dynamic> change;

  /// State payloads pre-formatted via `ISpectBlocSettings.formatState`.
  final Object formattedCurrentState;
  final Object formattedNextState;

  String get blocType => bloc.runtimeType.toString();

  /// Returns a raw, JSON-compatible map of the change.
  Map<String, dynamic> toJson() => <String, dynamic>{
        BlocJsonKeys.blocType: blocType,
        BlocJsonKeys.currentState: formattedCurrentState,
        BlocJsonKeys.nextState: formattedNextState,
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
