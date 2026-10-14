import 'dart:convert';
import 'dart:developer' as developer;

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/service_extensions/log_query.dart';

/// Maps one `ext.ispect.*` call onto [LogQuery] and its result onto a
/// [developer.ServiceExtensionResponse].
abstract final class ServiceExtensionHandler {
  static const methods = [
    ISpectServiceExtensions.getSummary,
    ISpectServiceExtensions.getLogs,
    ISpectServiceExtensions.getLog,
    ISpectServiceExtensions.getTrace,
  ];

  static developer.ServiceExtensionResponse handle(
    String method,
    Map<String, String> parameters, {
    required ISpectLogger? logger,
  }) {
    if (!kISpectEnabled) {
      return _error(
        developer.ServiceExtensionResponse.extensionError,
        'ISpect is compiled out; rebuild with --dart-define=ISPECT_ENABLED=true.',
      );
    }
    if (logger == null || logger.isDisposed) {
      return _error(
        developer.ServiceExtensionResponse.extensionError,
        'ISpect is not initialized; call ISpect.initialize or ISpect.run first.',
      );
    }
    final query = LogQuery(logger);
    try {
      final body = switch (method) {
        ISpectServiceExtensions.getSummary => query.summary(
            protocolVersion: ISpectServiceExtensions.protocolVersion,
          ),
        ISpectServiceExtensions.getLogs => query.logs(
            limit: _parseLimit(parameters['limit']),
            minLevel: _parseLevel(parameters['minLevel']),
            keys: _parseKeys(parameters['keys']),
            query: parameters['query'],
            afterId: _optional(parameters, 'afterId'),
            beforeId: _optional(parameters, 'beforeId'),
          ),
        ISpectServiceExtensions.getLog =>
          query.log(_required(parameters, 'id')),
        ISpectServiceExtensions.getTrace => query.trace(
            _required(parameters, 'id'),
            limit: ISpectServiceExtensions.maxLimit,
          ),
        _ => throw InvalidLogQuery(
            'Unknown method $method; use one of ${methods.join(', ')}.',
          ),
      };
      return developer.ServiceExtensionResponse.result(jsonEncode(body));
    } on InvalidLogQuery catch (e) {
      return _error(
        developer.ServiceExtensionResponse.invalidParams,
        e.message,
      );
    } catch (e) {
      return _error(
        developer.ServiceExtensionResponse.extensionError,
        'ISpect failed to answer $method (${e.runtimeType}).',
      );
    }
  }

  static int _parseLimit(String? raw) {
    if (raw == null || raw.isEmpty) return ISpectServiceExtensions.defaultLimit;
    final limit = int.tryParse(raw);
    if (limit == null ||
        limit < 1 ||
        limit > ISpectServiceExtensions.maxLimit) {
      throw InvalidLogQuery(
        'limit must be an integer from 1 to '
        '${ISpectServiceExtensions.maxLimit}, got "$raw".',
      );
    }
    return limit;
  }

  static LogLevel? _parseLevel(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final level in LogLevel.values) {
      if (level.name == raw) return level;
    }
    throw InvalidLogQuery(
      'minLevel must be one of '
      '${LogLevel.values.map((level) => level.name).join(', ')}, got "$raw".',
    );
  }

  static Set<String> _parseKeys(String? raw) =>
      raw
          ?.split(',')
          .map((key) => key.trim())
          .where((key) => key.isNotEmpty)
          .toSet() ??
      const {};

  static String? _optional(Map<String, String> parameters, String name) {
    final value = parameters[name];
    return value == null || value.isEmpty ? null : value;
  }

  static String _required(Map<String, String> parameters, String name) =>
      _optional(parameters, name) ??
      (throw InvalidLogQuery('Missing required parameter "$name".'));

  static developer.ServiceExtensionResponse _error(int code, String message) =>
      developer.ServiceExtensionResponse.error(code, message);
}
