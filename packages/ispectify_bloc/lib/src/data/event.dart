import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/bloc_json_keys.dart';

/// Snapshot of a BLoC `onEvent` invocation.
class BlocEventData {
  BlocEventData({
    required this.bloc,
    required this.event,
    required this.includeFullData,
  });

  final Bloc<dynamic, dynamic> bloc;
  final Object? event;

  /// Whether the raw [event] should be surfaced in [toJson] alongside its
  /// runtime type. Mirrors `ISpectBlocSettings.printEventFullData`.
  final bool includeFullData;

  String get blocType => bloc.runtimeType.toString();
  String get eventType => event.runtimeType.toString();

  /// Returns a raw, JSON-compatible map of the event.
  ///
  /// No redaction is applied. Call [redact] on the result when redaction
  /// is required.
  Map<String, dynamic> toJson() => <String, dynamic>{
        BlocJsonKeys.blocType: blocType,
        BlocJsonKeys.eventType: eventType,
        if (includeFullData && event != null) BlocJsonKeys.event: event,
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
