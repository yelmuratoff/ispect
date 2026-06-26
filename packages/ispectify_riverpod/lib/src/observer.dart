import 'package:ispectify/ispectify.dart';
import 'package:ispectify_riverpod/src/data/_data.dart';
import 'package:ispectify_riverpod/src/settings.dart';
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
    this.settings = const ISpectRiverpodSettings(),
    this.onProviderAdd,
    this.onProviderUpdate,
    this.onProviderDispose,
    this.onProviderFail,
    Iterable<Pattern> filters = const <Pattern>[],
    this.filterPredicate,
  }) : filters = List<Pattern>.unmodifiable(filters) {
    _logger = logger ?? ISpectLogger();
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

  bool _isFiltered(ProviderBase<Object?> provider) {
    final providerName = _providerName(provider);
    if (filterPredicate?.call(providerName) ?? false) {
      return true;
    }
    if (filters.isEmpty) {
      return false;
    }
    for (final pattern in filters) {
      if (providerName.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  bool _shouldLog({
    required bool toggle,
    required ProviderBase<Object?> provider,
  }) {
    if (!settings.enabled || !toggle) {
      return false;
    }
    if (settings.providerFilter?.call(provider) == false) {
      return false;
    }
    return !_isFiltered(provider);
  }

  void _logCallbackError(String callbackName, Object error) {
    try {
      _logger.warning(
        'ISpectRiverpodObserver: $callbackName callback threw: $error',
      );
    } catch (_) {}
  }

  /// Defaults to a [RedactionService] when redaction is enabled but no explicit
  /// redactor was supplied, so sensitive payloads are masked out of the box —
  /// matching the network/DB interceptors. `null` only when redaction is off.
  late final RedactionService? _redactor = settings.enableRedaction
      ? (settings.redactor ?? RedactionService())
      : null;

  Map<String, Object?> _withRedaction(
    Map<String, dynamic> data,
    void Function(Map<String, dynamic>, RedactionService) redact,
  ) {
    final redactor = _redactor;
    if (redactor != null) {
      redact(data, redactor);
    }
    return data;
  }

  static String _providerName(ProviderBase<Object?> provider) =>
      provider.name ?? provider.runtimeType.toString();

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    super.didAddProvider(provider, value, container);
    if (!_shouldLog(toggle: settings.printAdds, provider: provider)) {
      return;
    }
    try {
      onProviderAdd?.call(provider, value, container);
    } catch (callbackError) {
      _logCallbackError('onProviderAdd', callbackError);
    }

    final data = RiverpodAddData(
      provider: provider,
      value: value,
      includeValue: settings.printValues,
    );
    final meta = _withRedaction(data.toJson(), RiverpodAddData.redact);
    _logger.riverpodAdd(
      source: _source,
      target: data.providerName,
      meta: meta,
      consoleMessage: settings.printValues
          ? '[riverpod] add → ${data.providerName}\nValue: ${meta[RiverpodJsonKeys.value]}'
          : '[riverpod] add → ${data.providerName}',
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
    if (!_shouldLog(toggle: settings.printUpdates, provider: provider)) {
      return;
    }
    final accepted = settings.updateFilter?.call(
          provider,
          previousValue,
          newValue,
        ) ??
        true;
    if (!accepted) {
      return;
    }
    try {
      onProviderUpdate?.call(provider, previousValue, newValue, container);
    } catch (callbackError) {
      _logCallbackError('onProviderUpdate', callbackError);
    }

    final data = RiverpodUpdateData(
      provider: provider,
      previousValue: previousValue,
      newValue: newValue,
      includeValue: settings.printValues,
    );
    final meta = _withRedaction(data.toJson(), RiverpodUpdateData.redact);
    final previousFormatted = meta[RiverpodJsonKeys.previousValue] ??
        meta[RiverpodJsonKeys.previousValueType];
    final nextFormatted =
        meta[RiverpodJsonKeys.newValue] ?? meta[RiverpodJsonKeys.newValueType];
    _logger.riverpodUpdate(
      source: _source,
      target: data.providerName,
      meta: meta,
      consoleMessage:
          '[riverpod] update → ${data.providerName}\n$previousFormatted → $nextFormatted',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    super.didDisposeProvider(provider, container);
    if (!_shouldLog(toggle: settings.printDisposes, provider: provider)) {
      return;
    }
    try {
      onProviderDispose?.call(provider, container);
    } catch (callbackError) {
      _logCallbackError('onProviderDispose', callbackError);
    }

    final data = RiverpodDisposeData(provider: provider);
    final meta = _withRedaction(data.toJson(), RiverpodDisposeData.redact);
    _logger.riverpodDispose(
      source: _source,
      target: data.providerName,
      meta: meta,
      consoleMessage: '[riverpod] dispose → ${data.providerName}',
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
    if (!_shouldLog(toggle: settings.printFails, provider: provider)) {
      return;
    }
    try {
      onProviderFail?.call(provider, error, stackTrace, container);
    } catch (callbackError) {
      _logCallbackError('onProviderFail', callbackError);
    }

    final data = RiverpodFailData(
      provider: provider,
      error: error,
      stackTrace: stackTrace,
    );
    final meta = _withRedaction(data.toJson(), RiverpodFailData.redact);
    _logger.riverpodFail(
      source: _source,
      target: data.providerName,
      error: error,
      errorStackTrace: stackTrace,
      meta: meta,
      consoleMessage: '[riverpod] fail → ${data.providerName}',
    );
  }
}
