import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/file_log_codec.dart';

/// Byte, character, record, and node ceilings the rolling file history
/// applies when it writes, reads, imports, or exports records.
///
/// Every ceiling is the tighter of the storage budget in
/// [FileLogHistoryOptions] and the logger's [DiagnosticResourceLimits], so
/// neither side can be widened past the other.
final class FileLogLimits {
  const FileLogLimits({
    required FileLogHistoryOptions options,
    required ISpectLoggerOptions loggerOptions,
  })  : _options = options,
        _loggerOptions = loggerOptions;

  final FileLogHistoryOptions _options;
  final ISpectLoggerOptions _loggerOptions;

  DiagnosticResourceLimits get _resource => _loggerOptions.resourceLimits;

  int get recordBytes => _options.maxFileSize < _resource.maxLogRecordBytes
      ? _options.maxFileSize
      : _resource.maxLogRecordBytes;

  int get importCharacters =>
      _options.maxTotalSize < _resource.maxImportCharacters
          ? _options.maxTotalSize
          : _resource.maxImportCharacters;

  int get importBytes => _options.maxTotalSize < _resource.maxImportBytes
      ? _options.maxTotalSize
      : _resource.maxImportBytes;

  int get readRecords {
    // `{"time":0}` is the smallest accepted record. This source-size-derived
    // bound therefore remains comprehensive for every valid stored record
    // while placing a finite ceiling on hostile newline-dense inputs.
    const minimumValidRecordBytes = 10;
    final storageLimit = _options.maxTotalSize ~/ minimumValidRecordBytes + 1;
    return storageLimit < _resource.maxImportEntries
        ? storageLimit
        : _resource.maxImportEntries;
  }

  int get readNodes {
    final byRecords = readRecords * FileLogCodec.defaultMaxNodes + 1;
    final storageLimit =
        byRecords < _options.maxTotalSize ? byRecords : _options.maxTotalSize;
    return storageLimit < _resource.maxImportNodes
        ? storageLimit
        : _resource.maxImportNodes;
  }
}
