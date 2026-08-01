import 'package:ispectify/src/console_settings.dart';
import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/network/network_log_renderer.dart';
import 'package:ispectify/src/trace/trace_keys.dart';
import 'package:ispectify/src/utils/datetime_formatter.dart';

/// Renders a full [ISpectLogData] entry into a console-ready string.
///
/// Unlike `ILoggerFormatter` (which only decorates a pre-built string with
/// color/indent), implementations own the end-to-end shape of an output line
/// — level, source, category, timestamp, correlation metadata, and message.
///
/// Select the active implementation via [ConsoleSettings.formatter].
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
base class HumanLogEntryFormatter implements ILogEntryFormatter {
  const HumanLogEntryFormatter();

  @override
  String format(ISpectLogData data, ConsoleSettings settings) {
    final buffer = StringBuffer(_buildHeader(data, settings));
    final body = _buildBody(data);

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
}

/// Boxed console output: an opt-in alternative to [HumanLogEntryFormatter]
/// that frames each entry so individual logs stay distinct in a busy console.
///
/// ```text
/// ┌──────────────────────────────────────────────
/// │ INFO    [route] | 17:20:42.910 | Push | / → /detail
/// └──────────────────────────────────────────────
/// ```
///
/// Renders the same fields as [HumanLogEntryFormatter] (so redaction and
/// network-body rendering carry over unchanged); only the layout differs.
/// The border width comes from [ConsoleSettings.maxLineWidth]; the glyph comes
/// from [ConsoleSettings.lineSymbol], which must be a single character so the
/// border stays one column wide — any other value falls back to `─`. Color is
/// applied per line downstream by the active `ILoggerFormatter`, so the whole
/// box takes the entry's pen.
///
/// Enable via `ConsoleSettings(formatter: const BoxedLogEntryFormatter())`.
base class BoxedLogEntryFormatter implements ILogEntryFormatter {
  const BoxedLogEntryFormatter();

  static const String _fallbackGlyph = '─';

  @override
  String format(ISpectLogData data, ConsoleSettings settings) {
    final glyph =
        settings.lineSymbol.length == 1 ? settings.lineSymbol : _fallbackGlyph;
    final border = glyph * settings.maxLineWidth;
    final header = _buildHeader(data, settings);
    final body = _buildBody(data);
    final lines =
        body.isEmpty ? const ['(empty log message)'] : body.split('\n');

    final buffer = StringBuffer('┌$border')
      ..write('\n│ ')
      ..write(header)
      ..write(lines.first);
    for (final line in lines.skip(1)) {
      buffer
        ..write('\n│ ')
        ..write(line);
    }
    buffer.write('\n└$border');

    return buffer.toString();
  }
}

/// Builds the header segment shared by all entry formatters: padded level,
/// optional source/category labels, timestamp, and correlation metadata.
/// Ends with a trailing `| ` so a message can follow inline.
String _buildHeader(ISpectLogData data, ConsoleSettings settings) {
  final captured = captureISpectLogDataForEgress(data);
  final additionalData = captured.additionalData;
  final explicitLevel = captured.logLevel?.name;
  final levelFromKey = _levelFromKey(captured.key);
  final levelLabel = (explicitLevel ?? levelFromKey ?? 'log').toUpperCase();
  final paddedLevel = levelLabel.padRight(_levelColumnWidth);

  final source = _readNonEmptyString(additionalData, TraceKeys.source);
  final sourceLabel = source != null ? ' [$source]' : '';

  final keyIsLevel = captured.key != null &&
      (captured.key == explicitLevel || captured.key == levelFromKey);
  final categoryLabel =
      captured.key != null && !keyIsLevel ? ' [${captured.key}]' : '';

  final timestamp = settings.fullTimestamp
      ? ISpectDateTimeFormatter(captured.time).iso8601Local
      : ISpectDateTimeFormatter(captured.time).defaultFormat;

  final metadata = _buildMetadata(additionalData, settings);
  final metadataSection = metadata.isEmpty ? '' : ' $metadata |';

  return '$paddedLevel$sourceLabel$categoryLabel | $timestamp |$metadataSection ';
}

/// Builds the entry body shared by all formatters: the full text message
/// (message + error + exception + stack trace) plus the network body block
/// for network/WS entries. Returns an empty string when there is nothing to
/// show, letting each formatter render its own placeholder.
String _buildBody(ISpectLogData data) {
  final headline = NetworkLogRenderer.isNetworkLog(data)
      ? NetworkLogRenderer.renderHeadline(data)
      : data.toExportMessageText();
  final networkBody = NetworkLogRenderer.isNetworkLog(data)
      ? NetworkLogRenderer.renderBody(data)
      : '';
  if (networkBody.isEmpty) return headline;
  return headline.isEmpty ? networkBody : '$headline\n$networkBody';
}

String _buildMetadata(
  Map<String, dynamic>? additionalData,
  ConsoleSettings settings,
) {
  final parts = <String>[];
  final tid = _readNonEmptyString(additionalData, TraceKeys.transactionId);
  if (tid != null) {
    parts.add('tid=${settings.truncateTraceIds ? _shortenTraceId(tid) : tid}');
  }
  final cid = _readNonEmptyString(additionalData, TraceKeys.correlationId);
  if (cid != null) {
    parts.add('cid=${settings.truncateTraceIds ? _shortenTraceId(cid) : cid}');
  }
  final dur = _readInt(additionalData, TraceKeys.durationMs);
  if (dur != null) parts.add('dur=${dur}ms');
  return parts.join(' ');
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

String? _readNonEmptyString(Map<String, dynamic>? additionalData, String key) {
  final raw = additionalData?[key];
  if (raw is! String || raw.isEmpty) return null;
  return raw;
}

int? _readInt(Map<String, dynamic>? additionalData, String key) {
  final raw = additionalData?[key];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}
