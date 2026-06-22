import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/src/data/riverpod_json_keys.dart';
import 'package:riverpod/riverpod.dart';

/// Snapshot of a Riverpod `didUpdateProvider` event.
class RiverpodUpdateData {
  RiverpodUpdateData({
    required this.provider,
    required this.previousValue,
    required this.newValue,
    required this.includeValue,
  });

  final ProviderBase<Object?> provider;
  final Object? previousValue;
  final Object? newValue;

  /// Whether raw values should be surfaced in [toJson] alongside their runtime
  /// types. Mirrors `ISpectRiverpodSettings.printValues`.
  final bool includeValue;

  /// Human-readable provider label.
  String get providerName => provider.name ?? provider.runtimeType.toString();

  /// Returns a raw, JSON-compatible map of the event.
  ///
  /// No redaction is applied. Call [redact] on the result when redaction
  /// is required.
  Map<String, dynamic> toJson() => <String, dynamic>{
        RiverpodJsonKeys.providerName: providerName,
        RiverpodJsonKeys.providerType: provider.runtimeType.toString(),
        RiverpodJsonKeys.previousValueType:
            previousValue?.runtimeType.toString() ?? 'null',
        RiverpodJsonKeys.newValueType:
            newValue?.runtimeType.toString() ?? 'null',
        if (includeValue) ...{
          RiverpodJsonKeys.previousValue: previousValue,
          RiverpodJsonKeys.newValue: newValue,
        },
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
