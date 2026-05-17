import 'package:ispectify/src/filter/filter.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/trace/trace_keys.dart';

/// Matches logs whose [TraceKeys.category] is in [categories].
class CategoryFilter implements Filter<ISpectLogData> {
  const CategoryFilter(this.categories);
  final Set<String> categories;

  @override
  bool apply(ISpectLogData item) {
    final cat = item.additionalData?[TraceKeys.category];
    return cat is String && categories.contains(cat);
  }
}

/// Matches logs whose [TraceKeys.source] is in [sources].
class SourceFilter implements Filter<ISpectLogData> {
  const SourceFilter(this.sources);
  final Set<String> sources;

  @override
  bool apply(ISpectLogData item) {
    final src = item.additionalData?[TraceKeys.source];
    return src is String && sources.contains(src);
  }
}

/// Matches logs with a specific [TraceKeys.correlationId].
class CorrelationFilter implements Filter<ISpectLogData> {
  const CorrelationFilter(this.correlationId);
  final String correlationId;

  @override
  bool apply(ISpectLogData item) {
    final cid = item.additionalData?[TraceKeys.correlationId];
    return cid is String && cid == correlationId;
  }
}

/// Matches logs with a specific [TraceKeys.transactionId].
class TransactionFilter implements Filter<ISpectLogData> {
  const TransactionFilter(this.transactionId);
  final String transactionId;

  @override
  bool apply(ISpectLogData item) {
    final tid = item.additionalData?[TraceKeys.transactionId];
    return tid is String && tid == transactionId;
  }
}
