import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/diagnostic_capture_mode.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Bounded URL and path captured from caller-owned URL text.
///
/// [Uri] is implementable, and no cross-platform runtime check can prove that
/// an arbitrary instance was created by the Dart SDK. [fromUri] therefore uses
/// guarded formatting in balanced mode and returns an opaque snapshot in
/// strict mode. Callers that already own immutable URL text can bypass that
/// boundary with [fromTrustedText].
final class NetworkUriSnapshot {
  const NetworkUriSnapshot._({
    required this.url,
    required this.path,
    required this.isTrusted,
  });

  /// Captures a bounded URL in balanced mode, or an opaque strict snapshot.
  factory NetworkUriSnapshot.fromUri(
    Uri uri, {
    DiagnosticCaptureMode captureMode = DiagnosticCaptureMode.balanced,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    if (captureMode == DiagnosticCaptureMode.strict) return unavailable;
    try {
      return NetworkUriSnapshot.fromTrustedText(
        uri.toString(),
        resourceLimits: resourceLimits,
      );
    } on Object {
      return unavailable;
    }
  }

  /// Parses bounded URL text owned by the caller.
  ///
  /// Do not obtain [url] by formatting an arbitrary [Uri]. The parsed [Uri] is
  /// created inside this method, so reading its path does not cross an
  /// implementable-object trust boundary.
  factory NetworkUriSnapshot.fromTrustedText(
    String url, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    try {
      final prepared = _bound(url, resourceLimits);
      final parsed = Uri.tryParse(prepared);
      if (parsed == null) return unavailable;
      return NetworkUriSnapshot._(
        url: prepared,
        path: _bound(parsed.path, resourceLimits),
        isTrusted: true,
      );
    } on Object {
      return unavailable;
    }
  }

  /// Opaque snapshot used when URL text cannot be read safely.
  static const unavailable = NetworkUriSnapshot._(
    url: JsonValueNormalizer.unprintableValue,
    path: JsonValueNormalizer.unprintableValue,
    isTrusted: false,
  );

  /// Full, bounded URI text or [JsonValueNormalizer.unprintableValue].
  final String url;

  /// Bounded URI path or [JsonValueNormalizer.unprintableValue].
  final String path;

  /// Whether the snapshot came from caller-owned URL text.
  final bool isTrusted;

  static String _bound(
    String value,
    DiagnosticResourceLimits resourceLimits,
  ) =>
      LogExportOutput.truncateUtf8(
        value,
        maxBytes: resourceLimits.maxCapturedValueBytes,
      );
}
