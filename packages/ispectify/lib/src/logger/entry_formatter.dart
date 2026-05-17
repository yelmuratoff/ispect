import 'package:ispectify/src/console_settings.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/network/network_log_renderer.dart';
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
    final headline = data.textMessage;
    final networkBody = NetworkLogRenderer.isNetworkLog(data)
        ? NetworkLogRenderer.renderBody(data)
        : '';
    final body = networkBody.isEmpty
        ? headline
        : (headline.isEmpty ? networkBody : '$headline\n$networkBody');

    if (body.isEmpty) {
      buffer.write('(empty log message)');
    } else {
      final lines = body.split('\n');
      if (lines.length == 1) {
        buffer.write(lines.single);
      } else {
        for (final line in lines) {
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

    final metadata = _buildMetadata(data, settings);
    final metadataSection = metadata.isEmpty ? '' : ' $metadata |';

    return '$paddedLevel$sourceLabel$categoryLabel | $timestamp |$metadataSection ';
  }

  String _buildMetadata(ISpectLogData data, ConsoleSettings settings) {
    final parts = <String>[];
    final tid = _readNonEmptyString(data, TraceKeys.transactionId);
    if (tid != null) {
      parts
          .add('tid=${settings.truncateTraceIds ? _shortenTraceId(tid) : tid}');
    }
    final cid = _readNonEmptyString(data, TraceKeys.correlationId);
    if (cid != null) {
      parts
          .add('cid=${settings.truncateTraceIds ? _shortenTraceId(cid) : cid}');
    }
    final dur = _readInt(data, TraceKeys.durationMs);
    if (dur != null) parts.add('dur=${dur}ms');
    return parts.join(' ');
  }
}

/// Auto-generated trace IDs are 16-character hex (see `generateTraceId`).
/// Showing all 16 in the console is noise — the prefix is enough for visual
/// correlation, and the full value remains in `additionalData` for filtering
/// in the UI. Custom user-supplied IDs (e.g. `msg-1`, `txn-orders-2`) are
/// left untouched so they stay readable.
const int _shortIdLength = 8;

String _shortenTraceId(String id) {
  if (id.length < 16) return id;
  for (var i = 0; i < id.length; i++) {
    final c = id.codeUnitAt(i);
    final isHex = (c >= 0x30 && c <= 0x39) ||
        (c >= 0x61 && c <= 0x66) ||
        (c >= 0x41 && c <= 0x46);
    if (!isHex) return id;
  }
  return id.substring(0, _shortIdLength);
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
