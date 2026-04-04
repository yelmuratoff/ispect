import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/constants.dart';

/// Builds human-readable log messages for database operations.
final class DbMessageFormatter {
  const DbMessageFormatter._();

  /// Builds a human-readable log message from the provided fields.
  static String build({
    required String source,
    required String operation,
    String? table,
    String? target,
    String? key,
    int? items,
    int? affected,
    int? sizeBytes,
    bool? cacheHit,
    Duration? duration,
    bool? success,
    Object? value,
  }) {
    final buffer = StringBuffer('[$source] $operation');

    if (table != null && target != null) {
      buffer.write(' $table → $target');
    } else if (table != null) {
      buffer.write(' $table');
    } else if (target != null) {
      buffer.write(' $target');
    }

    final details = <String>[];
    if (key != null) details.add('${DbMessageLabels.keyPrefix}$key');
    if (value != null) details.add('${DbMessageLabels.valuePrefix}$value');
    if (items != null) details.add('${DbMessageLabels.itemsPrefix}$items');
    if (affected != null) {
      details.add('${DbMessageLabels.affectedPrefix}$affected');
    }
    if (sizeBytes != null) {
      details.add(
        '${DbMessageLabels.sizePrefix}${formatBytes(sizeBytes)}',
      );
    }
    if (cacheHit != null) {
      details.add(
        cacheHit ? DbMessageLabels.cacheHit : DbMessageLabels.cacheMiss,
      );
    }
    if (duration != null) {
      details.add(
        '${DbMessageLabels.durationPrefix}'
        '${duration.inMilliseconds}'
        '${DbMessageLabels.durationSuffix}',
      );
    }
    if (success != null) {
      details.add('${DbMessageLabels.successPrefix}$success');
    }

    if (details.isNotEmpty) {
      buffer.write('\n${details.join('\n')}');
    }

    return buffer.toString();
  }
}
