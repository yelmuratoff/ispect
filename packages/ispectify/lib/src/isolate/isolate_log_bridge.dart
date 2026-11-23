import 'dart:convert';
import 'dart:isolate';

import 'package:ispectify/ispectify.dart';

/// Adds logs sent from other isolates to a logger on the current isolate.
///
/// Pass [sendPort] to the background isolate and attach an
/// [ISpectIsolateLogForwarder] to the logger there. Entries arrive redacted
/// and bounded by that isolate's export, keep their time, level, and key, and
/// are recorded with [ISpectLogger.logData]. A message that is not a log
/// record, or is longer than `maxImportCharacters`, is dropped with a warning.
final class ISpectIsolateLogReceiver {
  ISpectIsolateLogReceiver._(this._logger, this._resourceLimits)
      : _port = ReceivePort('ISpect isolate logs') {
    _port.listen(_receive);
  }

  /// Opens a receiver for [logger], or returns `null` in builds compiled
  /// without `ISPECT_ENABLED`, where no port is opened.
  static ISpectIsolateLogReceiver? open(
    ISpectLogger logger, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    if (!kISpectEnabled) return null;
    resourceLimits.validate();
    return ISpectIsolateLogReceiver._(logger, resourceLimits);
  }

  final ISpectLogger _logger;
  final DiagnosticResourceLimits _resourceLimits;
  final ReceivePort _port;

  /// The port a background isolate forwards its logs to.
  SendPort get sendPort => _port.sendPort;

  /// Stops receiving. Logs sent afterwards are dropped.
  void close() => _port.close();

  void _receive(Object? message) {
    if (message is! String) {
      _logger.warning('ISpect isolate bridge dropped a non-text message');
      return;
    }
    if (message.length > _resourceLimits.maxImportCharacters) {
      _logger.warning(
        'ISpect isolate bridge dropped a log over maxImportCharacters',
      );
      return;
    }
    final ISpectLogData entry;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a log record object');
      }
      entry = ISpectLogDataJsonUtils.fromJson(
        decoded,
        resourceLimits: _resourceLimits,
      );
    } on FormatException {
      _logger.warning('ISpect isolate bridge dropped an unreadable log');
      return;
    }
    _logger.logData(entry);
  }
}

/// Forwards every log its logger records to an [ISpectIsolateLogReceiver] on
/// another isolate.
///
/// Each entry crosses the isolate boundary as one redacted JSON Lines record,
/// so the receiving isolate never sees values the export would mask. Builds
/// compiled without `ISPECT_ENABLED` send nothing.
///
/// ```dart
/// final logger = ISpectLogger()
///   ..addObserver(ISpectIsolateLogForwarder(sendPort));
/// ```
final class ISpectIsolateLogForwarder extends ISpectObserver {
  const ISpectIsolateLogForwarder(
    this._port, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) : _resourceLimits = resourceLimits;

  final SendPort _port;
  final DiagnosticResourceLimits _resourceLimits;

  @override
  void onError(ISpectLogData data) => _send(data);

  @override
  void onException(ISpectLogData data) => _send(data);

  @override
  void onLog(ISpectLogData data) => _send(data);

  void _send(ISpectLogData data) {
    if (!kISpectEnabled) return;
    _port.send(
      LogExporter.toJsonLines([data], resourceLimits: _resourceLimits),
    );
  }
}
