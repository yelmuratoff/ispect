import 'package:bloc/bloc.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_bloc/src/data/bloc_json_keys.dart';

/// Snapshot of a BLoC `onTransition` invocation.
class BlocTransitionData {
  BlocTransitionData({
    required this.bloc,
    required this.transition,
    required this.includeEventFullData,
    required this.formattedCurrentState,
    required this.formattedNextState,
  });

  final Bloc<dynamic, dynamic> bloc;
  final Transition<dynamic, dynamic> transition;

  /// Whether the raw triggering event should be surfaced in [toJson].
  /// Mirrors `ISpectBlocSettings.printEventFullData`.
  final bool includeEventFullData;

  /// State payloads pre-formatted via `ISpectBlocSettings.formatState`.
  final Object formattedCurrentState;
  final Object formattedNextState;

  String get blocType => bloc.runtimeType.toString();
  String get eventType => transition.event.runtimeType.toString();

  /// Returns a raw, JSON-compatible map of the transition.
  Map<String, dynamic> toJson() => <String, dynamic>{
        BlocJsonKeys.blocType: blocType,
        BlocJsonKeys.eventType: eventType,
        BlocJsonKeys.currentState: formattedCurrentState,
        BlocJsonKeys.nextState: formattedNextState,
        if (includeEventFullData) BlocJsonKeys.event: transition.event,
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
