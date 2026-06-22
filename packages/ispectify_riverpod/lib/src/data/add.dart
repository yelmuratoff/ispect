import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/src/data/riverpod_json_keys.dart';
import 'package:riverpod/riverpod.dart';

/// Snapshot of a Riverpod `didAddProvider` event.
class RiverpodAddData {
  RiverpodAddData({
    required this.provider,
    required this.value,
    required this.includeValue,
  });

  final ProviderBase<Object?> provider;
  final Object? value;

  /// Whether [value] should be surfaced in [toJson] or reduced to its
  /// runtime type. Mirrors `ISpectRiverpodSettings.printValues`.
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
        if (provider.argument != null)
          RiverpodJsonKeys.argument: '${provider.argument}',
        if (includeValue) RiverpodJsonKeys.value: value,
        if (!includeValue)
          RiverpodJsonKeys.valueType: value?.runtimeType.toString() ?? 'null',
      };

  /// Applies in-place redaction to a map produced by [toJson].
  static void redact(Map<String, dynamic> map, RedactionService redactor) {
    map.updateAll(
      (key, value) => redactor.redact(value, keyName: key),
    );
  }
}
