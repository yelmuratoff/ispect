import 'package:ispectify/src/filter/filter.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/trace/trace_keys.dart';

/// Matches logs by one string field of their trace metadata.
abstract class _TraceFieldFilter implements Filter<ISpectLogData> {
  const _TraceFieldFilter(this._field);

  final String _field;

  bool _matches(String value);

  @override
  bool apply(ISpectLogData item) {
    final value = captureISpectLogDataForEgress(item).additionalData?[_field];
    return value is String && _matches(value);
  }
}

/// Matches logs whose [TraceKeys.category] is in [categories].
class CategoryFilter extends _TraceFieldFilter {
  const CategoryFilter(this.categories) : super(TraceKeys.category);
  final Set<String> categories;

  @override
  bool _matches(String value) => categories.contains(value);
}

/// Matches logs whose [TraceKeys.source] is in [sources].
class SourceFilter extends _TraceFieldFilter {
  const SourceFilter(this.sources) : super(TraceKeys.source);
  final Set<String> sources;

  @override
  bool _matches(String value) => sources.contains(value);
}

/// Matches logs with a specific [TraceKeys.correlationId].
class CorrelationFilter extends _TraceFieldFilter {
  const CorrelationFilter(this.correlationId) : super(TraceKeys.correlationId);
  final String correlationId;

  @override
  bool _matches(String value) => value == correlationId;
}

/// Matches logs with a specific [TraceKeys.transactionId].
class TransactionFilter extends _TraceFieldFilter {
  const TransactionFilter(this.transactionId) : super(TraceKeys.transactionId);
  final String transactionId;

  @override
  bool _matches(String value) => value == transactionId;
}
