import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/bloc_json_keys.dart';
import 'package:ispectify_bloc/src/safe_type_label.dart';

/// Snapshot of a BLoC `onTransition` invocation.
class BlocTransitionData {
  BlocTransitionData({
    required this.bloc,
    required this.transition,
    required this.includeEventFullData,
    required this.formattedCurrentState,
    required this.formattedNextState,
    this.captureMode = DiagnosticCaptureMode.balanced,
    this.resourceLimits = DiagnosticResourceLimits.balanced,
  });

  final Bloc<dynamic, dynamic> bloc;
  final Transition<dynamic, dynamic> transition;

  /// Whether the raw triggering event should be surfaced in [toJson].
  /// Mirrors `ISpectBlocSettings.printEventFullData`.
  final bool includeEventFullData;

  /// State payloads pre-formatted via `ISpectBlocSettings.formatState`.
  final Object formattedCurrentState;
  final Object formattedNextState;

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

  String get eventType => safeValueTypeLabel(
        transition.event,
        captureMode: captureMode,
        resourceLimits: resourceLimits,
      );

  /// Returns a raw, JSON-compatible map of the transition.
  Map<String, dynamic> toJson() => <String, dynamic>{
        BlocJsonKeys.blocType: blocType,
        BlocJsonKeys.eventType: eventType,
        BlocJsonKeys.currentState: formattedCurrentState,
        BlocJsonKeys.nextState: formattedNextState,
        if (includeEventFullData) BlocJsonKeys.event: transition.event,
      };

  /// Applies in-place redaction to a map produced by [toJson].
  @Deprecated(
    'Observers prepare payloads through StateTracePreparer. '
    'Will be removed in 8.0.0.',
  )
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
