import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/bloc_json_keys.dart';
import 'package:ispectify_bloc/src/safe_type_label.dart';

/// Snapshot of a BLoC `onDone` invocation.
class BlocDoneData {
  BlocDoneData({
    required this.bloc,
    required this.event,
    required this.hasError,
    required this.includeFullData,
    this.captureMode = DiagnosticCaptureMode.balanced,
    this.resourceLimits = DiagnosticResourceLimits.balanced,
  });

  final Bloc<dynamic, dynamic> bloc;
  final Object? event;
  final bool hasError;

  /// Whether the raw [event] should be surfaced in [toJson] alongside its
  /// type label. Mirrors `ISpectBlocSettings.printEventFullData`.
  final bool includeFullData;

  /// Capture policy applied to type labels.
  /// Mirrors `ISpectBlocSettings.captureMode`.
  final DiagnosticCaptureMode captureMode;

  /// Budgets applied to type labels.
  /// Mirrors `ISpectBlocSettings.resourceLimits`.
  final DiagnosticResourceLimits resourceLimits;

  String get blocType => safeBlocTypeLabel(
        bloc,
        captureMode: captureMode,
        resourceLimits: resourceLimits,
      );

  String? get eventType => event == null
      ? null
      : safeBlocValueTypeLabel(
          event,
          captureMode: captureMode,
          resourceLimits: resourceLimits,
        );

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
