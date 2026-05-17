import 'package:meta/meta.dart';

/// Defines a trace category for grouping related log entries.
///
/// Each domain creates a `const` instance. [pickLogKey] determines the log key
/// based on error state and operation type.
@immutable
final class ISpectTraceCategory {
  const ISpectTraceCategory({
    required this.id,
    required this.successKey,
    required this.errorKey,
    this.secondaryKey,
    this.secondaryOperations = const {},
  });

  /// Category identifier (e.g. 'network', 'db', 'auth').
  final String id;

  /// Log key for successful operations (default).
  final String successKey;

  /// Log key for error operations.
  final String errorKey;

  /// Optional alternative success key for specific operations.
  final String? secondaryKey;

  /// Operations that use [secondaryKey] instead of [successKey].
  ///
  /// **Must be const** for @immutable contract.
  final Set<String> secondaryOperations;

  /// Determines the log key based on error state and operation.
  ///
  /// For HTTP: secondaryKey = 'http-request', secondaryOperations = {'GET', 'HEAD'}
  ///   → GET request → 'http-request'; POST response → 'http-response'; error → 'http-error'
  ///
  /// For DB: secondaryKey = 'db-query', secondaryOperations = {'query', 'get', 'select', ...}
  ///   → select → 'db-query'; insert → 'db-result'; error → 'db-error'
  String pickLogKey({required bool isError, required String operation}) {
    if (isError) return errorKey;
    if (secondaryKey != null && secondaryOperations.contains(operation)) {
      return secondaryKey!;
    }
    return successKey;
  }
}
