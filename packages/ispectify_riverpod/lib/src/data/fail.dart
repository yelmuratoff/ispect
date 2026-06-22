import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/src/data/riverpod_json_keys.dart';
import 'package:riverpod/riverpod.dart';

/// Snapshot of a Riverpod `providerDidFail` event.
class RiverpodFailData {
  RiverpodFailData({
    required this.provider,
    required this.error,
    required this.stackTrace,
  });

  final ProviderBase<Object?> provider;
  final Object error;
  final StackTrace stackTrace;

  /// Human-readable provider label.
  String get providerName => provider.name ?? provider.runtimeType.toString();

  /// Returns a raw, JSON-compatible map of the event.
  ///
  /// The raw [error] / [stackTrace] are intentionally omitted — they travel
  /// on the trace entry itself, not in `meta`.
  Map<String, dynamic> toJson() => <String, dynamic>{
        RiverpodJsonKeys.providerName: providerName,
        RiverpodJsonKeys.providerType: provider.runtimeType.toString(),
        RiverpodJsonKeys.errorType: error.runtimeType.toString(),
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
