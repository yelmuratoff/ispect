import 'dart:convert';
import 'dart:io';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/file_log_codec.dart';
import 'package:ispectify/src/history/file_log/file_log_layout.dart';
import 'package:ispectify/src/history/file_log/file_log_limits.dart';
import 'package:ispectify/src/history/file_log/managed_log_store.dart';
import 'package:ispectify/src/models/log_id.dart';

/// Decodes stored segments, archives, and legacy day files back into
/// [ISpectLogData], newest file first, deduplicated by id and sorted by time.
///
/// Per-record failures are reported through [onError] and skipped; access
/// failures propagate because they indicate tampering with the store.
final class SegmentReader {
  const SegmentReader({
    required ManagedLogStore store,
    required FileLogCodec codec,
    required FileLogHistoryOptions options,
    required ISpectLoggerOptions loggerOptions,
    required FileLogLimits limits,
    required String sessionId,
    required void Function(FileLogHistoryException error) onError,
  })  : _store = store,
        _codec = codec,
        _options = options,
        _loggerOptions = loggerOptions,
        _limits = limits,
        _sessionId = sessionId,
        _onError = onError;

  final ManagedLogStore _store;
  final FileLogCodec _codec;
  final FileLogHistoryOptions _options;
  final ISpectLoggerOptions _loggerOptions;
  final FileLogLimits _limits;
  final String _sessionId;
  final void Function(FileLogHistoryException error) _onError;

  ISpectLogData _roundTrip(
    ISpectLogData data, {
    required String sessionId,
  }) =>
      _codec.roundTrip(
        data,
        sessionId: sessionId,
        maxBytes: _limits.recordBytes,
      );

  Future<List<ISpectLogData>> readDirectory(Directory directory) async {
    final validated = await _store.validatedDateDirectory(
      directory.path,
      operation: 'readDirectory',
      allowMissing: true,
    );
    if (validated == null) return const [];
    return readFiles(
      await _store.segmentFiles(
        validated,
        includeArchives: true,
        operation: 'readDirectory',
      ),
    );
  }

  Future<List<ISpectLogData>> readFiles(Iterable<File> files) async {
    final byId = <String, ISpectLogData>{};
    var decodedBytes = 0;
    var inspectedRecords = 0;
    final orderedFiles = files.toList(growable: false);
    fileLoop:
    for (final file in orderedFiles.reversed) {
      final name = FileLogLayout.basename(file.path);
      if (FileLogLayout.legacyNamePattern.hasMatch(name)) {
        try {
          final legacyLength = await _store.managedFileLength(
            file,
            operation: 'readLegacy',
          );
          if (decodedBytes + legacyLength > _options.maxTotalSize) {
            _onError(
              FileLogLimitException(
                operation: 'readTotalSize',
                path: file.path,
              ),
            );
            break;
          }
          decodedBytes += legacyLength;
          final input = await _store.readLegacyText(file);
          final legacyLogs = _codec.decodeLegacyArray(
            input,
            maxCharacters: _limits.importCharacters,
            maxEncodedBytes: _limits.importBytes,
            maxDepth: _loggerOptions.resourceLimits.maxTraversalDepth,
            maxNodes: _limits.readNodes,
            maxCollectionItems:
                _loggerOptions.resourceLimits.maxCollectionItems,
            maxRootCollectionItems: _limits.readRecords,
          );
          for (final log in legacyLogs.reversed) {
            if (inspectedRecords >= _limits.readRecords) {
              _onError(
                const FileLogLimitException(operation: 'readRecordCount'),
              );
              break fileLoop;
            }
            inspectedRecords++;
            final safeLog = ISpectRedaction.enabled
                ? _roundTrip(
                    FileLogCodec.withoutSessionId(log),
                    sessionId: _sessionId,
                  )
                : log;
            final safeId = captureISpectLogDataForEgress(safeLog).id;
            byId.putIfAbsent(safeId, () => safeLog);
          }
        } on FileLogAccessException {
          rethrow;
        } on FileLogHistoryException catch (error) {
          _onError(error);
        } catch (error, stackTrace) {
          _onError(
            FileLogFormatException(
              operation: 'readLegacy',
              path: file.path,
              cause: error,
              stackTrace: stackTrace,
            ),
          );
        }
        continue;
      }

      List<int> bytes;
      try {
        bytes = await _store.readArtifactBytes(file);
      } on FileLogLimitException catch (error) {
        _onError(error);
        continue;
      } on FileLogAccessException {
        rethrow;
      } catch (error, stackTrace) {
        _onError(
          FileLogFormatException(
            operation: 'readSegment',
            path: file.path,
            cause: error,
            stackTrace: stackTrace,
          ),
        );
        continue;
      }
      if (bytes.isEmpty) continue;
      if (decodedBytes + bytes.length > _options.maxTotalSize) {
        _onError(
          FileLogLimitException(
            operation: 'readTotalSize',
            path: file.path,
          ),
        );
        break;
      }
      decodedBytes += bytes.length;
      final completeLength =
          bytes.last == 0x0A ? bytes.length : bytes.lastIndexOf(0x0A) + 1;
      if (completeLength == 0) continue;
      String text;
      try {
        text = utf8.decoder.convert(bytes, 0, completeLength);
      } on FormatException catch (_, stackTrace) {
        _onError(
          FileLogFormatException(
            operation: 'decodeSegmentUtf8',
            path: file.path,
            cause: const FormatException('Invalid file-log UTF-8'),
            stackTrace: stackTrace,
          ),
        );
        continue;
      }
      var lineEnd = text.length;
      for (var index = text.length - 1; index >= -1; index--) {
        if (index >= 0 && text.codeUnitAt(index) != 0x0a) continue;
        final lineStart = index + 1;
        if (lineStart == lineEnd) {
          lineEnd = index;
          continue;
        }
        if (inspectedRecords >= _limits.readRecords) {
          _onError(
            const FileLogLimitException(operation: 'readRecordCount'),
          );
          break fileLoop;
        }
        inspectedRecords++;
        final line = text.substring(lineStart, lineEnd);
        lineEnd = index;
        try {
          final log = _codec.decodeLine(
            line,
            maxCharacters: _limits.recordBytes,
            maxEncodedBytes: _limits.recordBytes,
            maxDepth: _loggerOptions.resourceLimits.maxTraversalDepth,
            maxNodes: _loggerOptions.resourceLimits.maxImportNodes,
            maxCollectionItems:
                _loggerOptions.resourceLimits.maxCollectionItems,
          );
          final storedSessionId = captureISpectLogDataForEgress(
            log,
          ).additionalData?[TraceKeys.sessionId];
          final safeLog = ISpectRedaction.enabled
              ? _roundTrip(
                  log,
                  sessionId: storedSessionId is String &&
                          LogId.isValid(storedSessionId)
                      ? storedSessionId
                      : _sessionId,
                )
              : log;
          final safeId = captureISpectLogDataForEgress(safeLog).id;
          byId.putIfAbsent(safeId, () => safeLog);
        } on FileLogLimitException catch (error) {
          _onError(error);
        } on FileLogAccessException {
          rethrow;
        } on FileLogFormatException catch (error) {
          _onError(error);
        }
      }
    }
    final logs = byId.values.toList()
      ..sort((left, right) {
        final capturedLeft = captureISpectLogDataForEgress(left);
        final capturedRight = captureISpectLogDataForEgress(right);
        final byTime = capturedLeft.time.compareTo(capturedRight.time);
        return byTime != 0
            ? byTime
            : capturedLeft.id.compareTo(capturedRight.id);
      });
    return logs;
  }

  Future<int> countDateEntries(DateTime date) async {
    var count = 0;
    var decodedBytes = 0;
    final directory = await _store.validatedDateDirectory(
      _store.dateDirectoryPath(date),
      operation: 'countDateEntries',
      allowMissing: true,
    );
    if (directory != null) {
      final files = await _store.segmentFiles(
        directory,
        includeArchives: true,
        operation: 'countDateEntries',
      );
      for (final file in files) {
        final bytes = await _store.readArtifactBytes(file);
        decodedBytes += bytes.length;
        if (decodedBytes > _options.maxTotalSize) {
          throw FileLogLimitException(
            operation: 'countDateEntries',
            path: file.path,
          );
        }
        final completeLength = bytes.isNotEmpty && bytes.last == 0x0A
            ? bytes.length
            : bytes.lastIndexOf(0x0A) + 1;
        if (completeLength == 0) continue;
        final text = utf8.decoder.convert(bytes, 0, completeLength);
        var lineStart = 0;
        for (var index = 0; index <= text.length; index++) {
          if (index != text.length && text.codeUnitAt(index) != 0x0a) {
            continue;
          }
          if (index > lineStart) {
            count++;
            if (count > _limits.readRecords) {
              throw const FileLogLimitException(
                operation: 'countDateEntries',
              );
            }
          }
          lineStart = index + 1;
        }
      }
    }
    final legacy = await _store.validatedLegacyFile(
      File(_store.legacyFilePath(date)),
      operation: 'countDateEntries',
      allowMissing: true,
    );
    if (legacy != null) {
      final legacyLength = await _store.managedFileLength(
        legacy,
        operation: 'countDateEntries',
      );
      if (decodedBytes + legacyLength > _options.maxTotalSize) {
        throw const FileLogLimitException(operation: 'countDateEntries');
      }
      count += _codec
          .decodeLegacyArray(
            await _store.readLegacyText(legacy),
            maxCharacters: _options.maxTotalSize,
            maxEncodedBytes: _options.maxTotalSize,
            maxNodes: _limits.readNodes,
            maxRootCollectionItems: _limits.readRecords,
          )
          .length;
      if (count > _limits.readRecords) {
        throw const FileLogLimitException(operation: 'countDateEntries');
      }
    }
    return count;
  }
}
