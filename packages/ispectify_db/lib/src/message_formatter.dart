import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/src/constants.dart';

/// Builds human-readable log messages for database operations.
///
/// `source` is omitted from the body by default — the entry formatter renders
/// it in the log header (`[source]`), so duplicating it here just adds noise.
/// Pass [printSourceInBody] = `true` to re-introduce the prefix when the
/// message is read out of context (e.g. exported logs).
final class DbMessageFormatter {
  const DbMessageFormatter._();

  /// Builds a human-readable log message from the provided fields.
  static String build({
    required String operation,
    String? source,
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
    bool printSourceInBody = false,
  }) {
    final buffer = StringBuffer();
    if (printSourceInBody && source != null && source.isNotEmpty) {
      buffer.write('[$source] ');
    }
    buffer.write(operation);

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
