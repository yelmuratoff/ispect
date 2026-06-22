import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/bloc_json_keys.dart';

/// Snapshot of a BLoC `onDone` invocation.
class BlocDoneData {
  BlocDoneData({
    required this.bloc,
    required this.event,
    required this.hasError,
    required this.includeFullData,
  });

  final Bloc<dynamic, dynamic> bloc;
  final Object? event;
  final bool hasError;

  /// Whether the raw [event] should be surfaced in [toJson] alongside its
  /// runtime type. Mirrors `ISpectBlocSettings.printEventFullData`.
  final bool includeFullData;

  String get blocType => bloc.runtimeType.toString();
  String? get eventType => event?.runtimeType.toString();

  /// Returns a raw, JSON-compatible map of the completion event.
  Map<String, dynamic> toJson() => <String, dynamic>{
        BlocJsonKeys.blocType: blocType,
        if (event != null) BlocJsonKeys.eventType: eventType,
        if (includeFullData && event != null) BlocJsonKeys.event: event,
        BlocJsonKeys.hasError: hasError,
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
