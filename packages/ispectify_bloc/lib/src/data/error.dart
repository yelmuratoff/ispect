import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/bloc_json_keys.dart';

/// Snapshot of a BLoC / Cubit `onError` invocation.
class BlocErrorData {
  BlocErrorData({
    required this.bloc,
    required this.error,
    required this.stackTrace,
  });

  final BlocBase<dynamic> bloc;
  final Object error;
  final StackTrace stackTrace;

  String get blocType => bloc.runtimeType.toString();

  /// Returns a raw, JSON-compatible map of the error event.
  ///
  /// The raw [error] / [stackTrace] are intentionally omitted — they travel on
  /// the trace entry itself, not in `meta`.
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
