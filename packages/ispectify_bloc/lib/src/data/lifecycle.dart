import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/bloc_json_keys.dart';

/// Snapshot of a BLoC / Cubit lifecycle invocation (`onCreate`, `onClose`).
///
/// Both events share the same meta shape, so a single data class covers them.
class BlocLifecycleData {
  BlocLifecycleData({required this.bloc});

  final BlocBase<dynamic> bloc;

  String get blocType => bloc.runtimeType.toString();

  /// Returns a raw, JSON-compatible map of the lifecycle event.
  Map<String, dynamic> toJson() => <String, dynamic>{
        BlocJsonKeys.blocType: blocType,
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
