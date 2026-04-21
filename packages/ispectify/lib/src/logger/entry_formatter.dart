import 'package:ispectify/src/console_settings.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/trace/trace_keys.dart';
import 'package:ispectify/src/utils/datetime_formatter.dart';

/// Renders a full [ISpectLogData] entry into a console-ready string.
///
/// Unlike `ILoggerFormatter` (which only decorates a pre-built string with
/// color/indent), implementations own the end-to-end shape of an output line
/// — level, source, category, timestamp, correlation metadata, and message.
abstract interface class ILogEntryFormatter {
  String format(ISpectLogData data, ConsoleSettings settings);
}

/// Width of the level column. Fits `WARNING`/`VERBOSE` exactly; `CRITICAL`
/// overflows by one character — acceptable since critical logs are rare and
/// should stand out anyway.
const int _levelColumnWidth = 7;

const Set<String> _levelKeyNames = <String>{
  'critical',
  'error',
  'warning',
  'info',
  'debug',
  'verbose',
};

String? _levelFromKey(String? key) =>
    key != null && _levelKeyNames.contains(key) ? key : null;

/// Human-readable, grep-friendly console output.
///
/// Layout: `LEVEL   [source] [category] | time | tid=… cid=… dur=…ms | message`
///
/// All metadata fields between the timestamp and message are optional and
/// only rendered when present in [ISpectLogData.additionalData].
class HumanLogEntryFormatter implements ILogEntryFormatter {
  const HumanLogEntryFormatter();

  @override
  String format(ISpectLogData data, ConsoleSettings settings) {
    final buffer = StringBuffer(_buildHeader(data, settings));
    final body = data.textMessage;
    if (body.isEmpty) {
      buffer.write('(empty log message)');
    } else {
      final lines = body.split('\n');
      if (lines.length == 1) {
        buffer.write(lines.single);
      } else {
        buffer.write(lines.first);
        for (final line in lines.skip(1)) {
          buffer
            ..write('\n  ')
            ..write(line);
        }
      }
    }

    return buffer.toString();
  }

  String _buildHeader(ISpectLogData data, ConsoleSettings settings) {
    final explicitLevel = data.logLevel?.name;
    final levelFromKey = _levelFromKey(data.key);
    final levelLabel = (explicitLevel ?? levelFromKey ?? 'log').toUpperCase();
    final paddedLevel = levelLabel.padRight(_levelColumnWidth);

    final source = _readNonEmptyString(data, TraceKeys.source);
    final sourceLabel = source != null ? ' [$source]' : '';

    final keyIsLevel = data.key != null &&
        (data.key == explicitLevel || data.key == levelFromKey);
    final categoryLabel =
        data.key != null && !keyIsLevel ? ' [${data.key}]' : '';

    final timestamp = settings.fullTimestamp
        ? ISpectDateTimeFormatter(data.time).iso8601Local
        : data.formattedTime;

    final metadata = _buildMetadata(data);
    final metadataSection = metadata.isEmpty ? '' : ' $metadata |';

    return '$paddedLevel$sourceLabel$categoryLabel | $timestamp |$metadataSection ';
  }

  String _buildMetadata(ISpectLogData data) {
    final parts = <String>[];
    final tid = _readNonEmptyString(data, TraceKeys.transactionId);
    if (tid != null) parts.add('tid=$tid');
    final cid = _readNonEmptyString(data, TraceKeys.correlationId);
    if (cid != null) parts.add('cid=$cid');
    final dur = _readInt(data, TraceKeys.durationMs);
    if (dur != null) parts.add('dur=${dur}ms');
    return parts.join(' ');
  }
}

String? _readNonEmptyString(ISpectLogData data, String key) {
  final raw = data.additionalData?[key];
  if (raw is! String || raw.isEmpty) return null;
  return raw;
}

int? _readInt(ISpectLogData data, String key) {
  final raw = data.additionalData?[key];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}
