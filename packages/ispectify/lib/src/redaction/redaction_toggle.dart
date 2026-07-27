import 'dart:async';

import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:meta/meta.dart';

/// Global default policy and kill-switch for all ISpect redaction.
///
/// Every redaction path routes through this gate: network interceptors
/// (Dio/HTTP/WS), database tracing, BLoC/Riverpod observers, the trace
/// pipeline, navigation route arguments, and every export path (JSON, text,
/// Markdown, file share, clipboard, cURL).
///
/// Configure [service] once to apply application-specific masking across core
/// diagnostics and supported integrations. Explicit integration services stay
/// local overrides. Setting [enabled] to `false` disables content masking
/// everywhere at once, overriding per-integration `enableRedaction` flags.
///
/// Defaults to `true`. Because captured diagnostics can contain sensitive data,
/// disabling redaction is a deliberate opt-out — leave it on unless a build
/// genuinely needs raw payloads.
///
/// ```dart
/// ISpectRedaction.configure(
///   service: RedactionService(
///     additionalSensitiveKeys: {'tenant_secret'},
///   ),
/// );
///
/// // Deliberate local-debugging opt-out:
/// ISpect.run(() => runApp(MyApp()), redactionEnabled: false);
/// ```
abstract final class ISpectRedaction {
  /// Whether redaction is active across all ISpect diagnostics.
  ///
  /// `true` by default. When `false`, [RedactionService] instance and static
  /// methods pass data through unchanged and the navigation observer logs full
  /// route arguments.
  static bool _enabled = true;

  static final Object _zonePolicyKey = Object();

  static bool get enabled {
    final scoped = Zone.current[_zonePolicyKey];
    return scoped is _ScopedRedactionPolicy ? scoped.enabled : _enabled;
  }

  static set enabled(bool value) => _enabled = value;

  static RedactionService? _service;

  /// The default redaction policy used by every ISpect integration.
  ///
  /// Explicit per-integration services remain local overrides. The global
  /// service is resolved when a diagnostic operation runs, so reconfiguration
  /// also applies to integrations that already exist in the current isolate.
  static RedactionService get service {
    final scoped = Zone.current[_zonePolicyKey];
    if (scoped is _ScopedRedactionPolicy) return scoped.service;
    return _service ??= RedactionService();
  }

  /// Runs internal asynchronous work against an immutable policy snapshot.
  @internal
  static T runWithPolicy<T>({
    required bool enabled,
    required RedactionService service,
    required T Function() body,
  }) =>
      runZoned(
        body,
        zoneValues: {
          _zonePolicyKey: _ScopedRedactionPolicy(
            enabled: enabled,
            service: service,
          ),
        },
      );

  /// Updates the process-isolate redaction defaults.
  ///
  /// Omitted values preserve their current setting.
  static void configure({
    bool? enabled,
    RedactionService? service,
  }) {
    if (enabled != null) ISpectRedaction.enabled = enabled;
    if (service != null) _service = service;
  }

  /// Resolves a redaction service using the shared precedence contract.
  ///
  /// An explicit [service] wins, followed by explicit [sensitiveKeys], then
  /// the globally configured [ISpectRedaction.service].
  static RedactionService resolveService({
    RedactionService? service,
    Iterable<String>? sensitiveKeys,
  }) {
    if (service != null) return service;
    if (sensitiveKeys != null && sensitiveKeys.isNotEmpty) {
      return RedactionService(sensitiveKeys: sensitiveKeys.toSet());
    }
    return ISpectRedaction.service;
  }

  /// Restores enabled redaction with a fresh default service.
  static void reset() {
    _enabled = true;
    _service = null;
  }
}

final class _ScopedRedactionPolicy {
  const _ScopedRedactionPolicy({
    required this.enabled,
    required this.service,
  });

  final bool enabled;
  final RedactionService service;
}
