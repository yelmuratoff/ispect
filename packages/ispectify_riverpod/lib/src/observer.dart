import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/src/data/_data.dart';
import 'package:ispectify_riverpod/src/safe_type_label.dart';
import 'package:ispectify_riverpod/src/settings.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

typedef RiverpodProviderCallback = void Function(
  ProviderBase<Object?> provider,
  ProviderContainer container,
);

typedef RiverpodAddCallback = void Function(
  ProviderBase<Object?> provider,
  Object? value,
  ProviderContainer container,
);

typedef RiverpodUpdateCallback = void Function(
  ProviderBase<Object?> provider,
  Object? previousValue,
  Object? newValue,
  ProviderContainer container,
);

typedef RiverpodFailCallback = void Function(
  ProviderBase<Object?> provider,
  Object error,
  StackTrace stackTrace,
  ProviderContainer container,
);

typedef RiverpodFilterPredicate = bool Function(Object? candidate);

/// Riverpod observer that logs provider lifecycle events via the unified
/// trace API under the `riverpod-add`, `riverpod-update`, `riverpod-dispose`,
/// and `riverpod-fail` log keys.
class ISpectRiverpodObserver extends ProviderObserver {
  ISpectRiverpodObserver({
    ISpectLogger? logger,
    this.settings = ISpectRiverpodSettings.verbose,
    this.onProviderAdd,
    this.onProviderUpdate,
    this.onProviderDispose,
    this.onProviderFail,
    Iterable<Pattern> filters = const <Pattern>[],
    this.filterPredicate,
  }) : filters = List<Pattern>.unmodifiable(filters) {
    _logger = logger ?? ISpectLogger();
    settings.resourceLimits?.validate();
  }

  late final ISpectLogger _logger;
  final RiverpodAddCallback? onProviderAdd;
  final RiverpodUpdateCallback? onProviderUpdate;
  final RiverpodProviderCallback? onProviderDispose;
  final RiverpodFailCallback? onProviderFail;
  final ISpectRiverpodSettings settings;
  final List<Pattern> filters;
  final RiverpodFilterPredicate? filterPredicate;

  static const String _source = 'riverpod';

  /// Test-only override for the compile-time [kISpectEnabled] gate.
  ///
  /// This can only narrow the compile-time gate; it can never enable ISpect
  /// when the build omitted `ISPECT_ENABLED`.
  @visibleForTesting
  static bool? debugEnabledOverride;

  bool get _ispectEnabled => kISpectEnabled && (debugEnabledOverride ?? true);
  bool get _loggingEnabled =>
      _ispectEnabled && _logger.isEnabled && settings.enabled;
  bool get _captureEnabled => _loggingEnabled && _logger.hasActiveConsumers;
  DiagnosticResourceLimits get _resourceLimits =>
      settings.resourceLimits ?? _logger.options.resourceLimits;

  bool _isFiltered(ProviderBase<Object?> provider) {
    final providerName = _providerName(provider);
    final predicateMatch = filterPredicate?.call(providerName) ?? false;
    if (!_loggingEnabled) {
      return true;
    }
    if (predicateMatch) {
      return true;
    }
    if (filters.isEmpty) {
      return false;
    }
    for (final pattern in filters) {
      final matches = providerName.contains(pattern);
      if (!_loggingEnabled) return true;
      if (matches) {
        return true;
      }
    }
    return false;
  }

  bool _shouldLog({
    required bool toggle,
    required ProviderBase<Object?> provider,
    bool hasAdapterCallback = false,
  }) {
    if (!_loggingEnabled || !toggle) {
      return false;
    }
    if (!_captureEnabled && !hasAdapterCallback) {
      return false;
    }
    final accepted = settings.providerFilter?.call(provider) ?? true;
    if (!_loggingEnabled || !accepted) {
      return false;
    }
    final filtered = _isFiltered(provider);
    return _loggingEnabled && !filtered;
  }

  void _logCallbackError(String callbackName, Object _) {
    try {
      _logger.warning(
        'ISpectRiverpodObserver: $callbackName callback threw safely.',
      );
    } catch (_) {}
  }

  RedactionService? get _redactor => settings.isRedactionActive
      ? ISpectRedaction.resolveService(service: settings.redactor)
      : null;
  // Every caller-controlled trace field is prepared below. A second generic
  // pass would replace the configured redactor and repeat boundary traversal.
  ISpectTraceConfig get _traceConfig => ISpectTraceConfig(
        redact: false,
        attachStackOnError: true,
        resourceLimits: _resourceLimits,
      );

  bool get _redactionActive => settings.isRedactionActive;

  Object? _prepareTraceValue(Object? value) {
    final redactor = _redactor;
    final redactionActive = _redactionActive;
    final prepared = LogExportOutput.boundJsonValue(
      value,
      maxBytes: _resourceLimits.maxStateTraceBytes,
      resourceLimits: _resourceLimits,
      preserveTypes: redactionActive,
      replaceOversizedStrings: redactionActive,
      allowCustomSerialization:
          settings.captureMode == DiagnosticCaptureMode.balanced,
      allowCustomStringification:
          settings.captureMode == DiagnosticCaptureMode.balanced,
    );
    if (!redactionActive) return prepared;
    try {
      final redacted = redactor!.redactForExport(
        LogExportOutput.replaceTruncatedPrefixes(
          prepared,
          resourceLimits: _resourceLimits,
        ),
        resourceLimits: _resourceLimits,
      );
      return LogExportOutput.boundJsonValue(
        redacted,
        maxBytes: _resourceLimits.maxStateTraceBytes,
        resourceLimits: _resourceLimits,
        replaceOversizedStrings: true,
      );
    } catch (_) {
      return '[REDACTED]';
    }
  }

  String _prepareTraceText(Object? value) {
    final prepared = _prepareTraceValue(value);
    return switch (prepared) {
      final String value => value,
      final num value => value.toString(),
      final bool value => value.toString(),
      _ => '[REDACTED]',
    };
  }

  Object? _prepareTraceError(Object? error) {
    if (error == null) return null;
    return _prepareTraceText(error);
  }

  StackTrace? _prepareTraceStack(StackTrace? stackTrace) {
    if (stackTrace == null) return null;
    return StackTrace.fromString(_prepareTraceText(stackTrace));
  }

  Map<String, Object?> _prepareTraceMeta(Map<String, dynamic> data) {
    final prepared = _prepareTraceValue(data);
    if (prepared is Map) {
      final result = <String, Object?>{};
      for (final entry in prepared.entries) {
        if (entry.key case final String key) {
          result[key] = entry.value;
        }
      }
      return result;
    }
    return <String, Object?>{};
  }

  String _traceTarget(
    Map<String, Object?> meta,
    String key,
    String fallback,
  ) {
    final value = meta[key];
    if (value is String) return value;
    return _redactionActive ? '[REDACTED]' : _prepareTraceText(fallback);
  }

  String _providerName(ProviderBase<Object?> provider) =>
      LogExportOutput.truncateUtf8(
        provider.name ?? safeRiverpodProviderTypeLabel(provider),
        maxBytes: _resourceLimits.maxStateTraceBytes,
      );

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    super.didAddProvider(provider, value, container);
    if (!_shouldLog(
      toggle: settings.printAdds,
      provider: provider,
      hasAdapterCallback: onProviderAdd != null,
    )) {
      return;
    }
    try {
      onProviderAdd?.call(provider, value, container);
    } catch (callbackError) {
      _logCallbackError('onProviderAdd', callbackError);
    }
    if (!_captureEnabled) {
      return;
    }

    final data = RiverpodAddData(
      provider: provider,
      value: value,
      includeValue: settings.printValues,
    );
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(
      meta,
      RiverpodJsonKeys.providerName,
      data.providerName,
    );
    _logger.riverpodAdd(
      source: _source,
      target: target,
      meta: meta,
      config: _traceConfig,
      consoleMessage: _prepareTraceText(
        settings.printValues
            ? '[riverpod] add → $target\n'
                'Value: ${meta[RiverpodJsonKeys.value]}'
            : '[riverpod] add → $target',
      ),
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    super.didUpdateProvider(provider, previousValue, newValue, container);
    if (!_shouldLog(
      toggle: settings.printUpdates,
      provider: provider,
      hasAdapterCallback: onProviderUpdate != null,
    )) {
      return;
    }
    final accepted = settings.updateFilter?.call(
          provider,
          previousValue,
          newValue,
        ) ??
        true;
    if (!_loggingEnabled) {
      return;
    }
    if (!accepted) {
      return;
    }
    try {
      onProviderUpdate?.call(provider, previousValue, newValue, container);
    } catch (callbackError) {
      _logCallbackError('onProviderUpdate', callbackError);
    }
    if (!_captureEnabled) {
      return;
    }

    final data = RiverpodUpdateData(
      provider: provider,
      previousValue: previousValue,
      newValue: newValue,
      includeValue: settings.printValues,
    );
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(
      meta,
      RiverpodJsonKeys.providerName,
      data.providerName,
    );
    final previousFormatted = meta[RiverpodJsonKeys.previousValue] ??
        meta[RiverpodJsonKeys.previousValueType];
    final nextFormatted =
        meta[RiverpodJsonKeys.newValue] ?? meta[RiverpodJsonKeys.newValueType];
    _logger.riverpodUpdate(
      source: _source,
      target: target,
      meta: meta,
      config: _traceConfig,
      consoleMessage: _prepareTraceText(
        '[riverpod] update → $target\n'
        '$previousFormatted → $nextFormatted',
      ),
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    super.didDisposeProvider(provider, container);
    if (!_shouldLog(
      toggle: settings.printDisposes,
      provider: provider,
      hasAdapterCallback: onProviderDispose != null,
    )) {
      return;
    }
    try {
      onProviderDispose?.call(provider, container);
    } catch (callbackError) {
      _logCallbackError('onProviderDispose', callbackError);
    }
    if (!_captureEnabled) {
      return;
    }

    final data = RiverpodDisposeData(provider: provider);
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(
      meta,
      RiverpodJsonKeys.providerName,
      data.providerName,
    );
    _logger.riverpodDispose(
      source: _source,
      target: target,
      meta: meta,
      config: _traceConfig,
      consoleMessage: _prepareTraceText(
        '[riverpod] dispose → $target',
      ),
    );
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    super.providerDidFail(provider, error, stackTrace, container);
    if (!_shouldLog(
      toggle: settings.printFails,
      provider: provider,
      hasAdapterCallback: onProviderFail != null,
    )) {
      return;
    }
    try {
      onProviderFail?.call(provider, error, stackTrace, container);
    } catch (callbackError) {
      _logCallbackError('onProviderFail', callbackError);
    }
    if (!_captureEnabled) {
      return;
    }

    final data = RiverpodFailData(
      provider: provider,
      error: error,
      stackTrace: stackTrace,
    );
    final meta = _prepareTraceMeta(data.toJson());
    final target = _traceTarget(
      meta,
      RiverpodJsonKeys.providerName,
      data.providerName,
    );
    _logger.riverpodFail(
      source: _source,
      target: target,
      error: _prepareTraceError(error)!,
      errorStackTrace: _prepareTraceStack(stackTrace),
      meta: meta,
      config: _traceConfig,
      consoleMessage: _prepareTraceText(
        '[riverpod] fail → $target',
      ),
    );
  }
}
