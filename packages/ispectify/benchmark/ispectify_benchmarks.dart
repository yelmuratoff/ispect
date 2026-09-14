import 'dart:convert';
import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ispectify/ispectify.dart';

void main(List<String> arguments) {
  final outputPath = _outputPath(arguments);
  final results = <_BenchmarkResult>[
    _LoggerBenchmark(
      'logger.metadata-only',
      additionalData: null,
      maxHistoryItems: 1000,
    ).result(),
    _LoggerBenchmark(
      'logger.with-payload',
      additionalData: _payload(1024),
      maxHistoryItems: 1000,
    ).result(),
    _LoggerBenchmark(
      'logger.with-payload.strict',
      additionalData: _payload(1024),
      captureMode: DiagnosticCaptureMode.strict,
      maxHistoryItems: 1000,
    ).result(),
    _LoggerBenchmark(
      'logger.with-payload.redaction-disabled',
      additionalData: _payload(1024),
      enableRedaction: false,
      maxHistoryItems: 1000,
    ).result(),
    _LoggerBenchmark(
      'logger.metadata-only.console',
      additionalData: null,
      maxHistoryItems: 1000,
      useConsoleLogs: true,
    ).result(),
    _LoggerBenchmark(
      'logger.with-payload.console',
      additionalData: _payload(1024),
      maxHistoryItems: 1000,
      useConsoleLogs: true,
    ).result(),
    _CaptureBenchmark('capture.with-payload', _payload(1024)).result(),
    _ExportHistoryBenchmark('export.history.json-lines.100', 100).result(),
    _ExportHistoryBenchmark(
      'export.history.text.100',
      100,
      format: _HistoryExportFormat.text,
    ).result(),
    _LoggerBenchmark(
      'logger.history-disabled',
      additionalData: null,
      useHistory: false,
    ).result(),
    _LoggerBenchmark(
      'logger.bounded-history',
      additionalData: null,
      maxHistoryItems: 1000,
    ).result(),
    for (final size in <int>[1024, 10 * 1024, 100 * 1024])
      _RedactionBenchmark('redaction.${size ~/ 1024}kb', _payload(size))
          .result(),
    _ExportRedactionBenchmark('redaction.export.1kb', _payload(1024)).result(),
    _SnapshotBenchmark('snapshot.1kb', _payload(1024)).result(),
    _ExportBenchmark('export.json-lines.100', _logs(100)).result(),
    _ExportBenchmark('export.json-lines.1000', _logs(1000)).result(),
    _ExportBenchmark(
      'export.json-lines.100.redaction-disabled',
      _logs(100),
      enableRedaction: false,
    ).result(),
    _ExportBenchmark(
      'export.json-lines.1000.redaction-disabled',
      _logs(1000),
      enableRedaction: false,
    ).result(),
  ];

  final report = <String, Object?>{
    'dart-version': Platform.version,
    'operating-system': Platform.operatingSystem,
    'results': results.map((result) => result.toJson()).toList(),
  };
  const encoder = JsonEncoder.withIndent('  ');
  stdout.writeln(encoder.convert(report));

  if (outputPath != null) {
    File(outputPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('${encoder.convert(report)}\n');
  }
}

String? _outputPath(List<String> arguments) {
  if (arguments.length == 2 && arguments.first == '--output') {
    return arguments.last;
  }
  if (arguments.isEmpty) return null;
  throw ArgumentError('Usage: ispectify_benchmarks [--output <path>]');
}

Map<String, Object?> _payload(int bytes) => <String, Object?>{
      'event': 'benchmark',
      'body': List<Map<String, String>>.generate(
        bytes ~/ 32,
        (index) => <String, String>{'field': 'value-$index', 'status': 'ok'},
      ),
      'nested': <String, Object?>{'token': 'benchmark-token'},
    };

List<ISpectLogData> _logs(int count) => List<ISpectLogData>.generate(
      count,
      (index) => ISpectLogData(
        'Benchmark log $index',
        id: 'benchmark-$index',
        key: ISpectLogType.info.key,
        logLevel: LogLevel.info,
        time: DateTime.utc(2026),
        additionalData: <String, dynamic>{
          'body': 'x' * 256,
          'token': 'benchmark-token',
        },
      ),
      growable: false,
    );

final class _LoggerBenchmark extends BenchmarkBase {
  _LoggerBenchmark(
    super.name, {
    required this.additionalData,
    this.useHistory = true,
    this.maxHistoryItems = 0,
    this.captureMode = DiagnosticCaptureMode.balanced,
    this.enableRedaction = true,
    this.useConsoleLogs = false,
  });

  final Map<String, Object?>? additionalData;
  final bool useHistory;
  final int maxHistoryItems;
  final DiagnosticCaptureMode captureMode;
  final bool enableRedaction;
  final bool useConsoleLogs;
  late final ISpectLogger _logger;

  @override
  void setup() {
    ISpectRedaction.enabled = enableRedaction;
    _logger = ISpectLogger(
      logger: ISpectBaseLogger(output: _discard),
      options: ISpectLoggerOptions(
        useConsoleLogs: useConsoleLogs,
        useHistory: useHistory,
        maxHistoryItems: maxHistoryItems,
        captureMode: captureMode,
      ),
    );
  }

  static void _discard(
    String message, {
    LogLevel? logLevel,
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {}

  @override
  void exercise() {
    _logger.info('Benchmark event', additionalData: additionalData);
  }

  _BenchmarkResult result() => _BenchmarkResult(name, super.measure());

  @override
  void teardown() {
    _logger.dispose();
    ISpectRedaction.enabled = true;
  }
}

enum _HistoryExportFormat { jsonLines, text }

final class _ExportHistoryBenchmark extends BenchmarkBase {
  _ExportHistoryBenchmark(
    super.name,
    this.count, {
    this.format = _HistoryExportFormat.jsonLines,
  });

  final int count;
  final _HistoryExportFormat format;
  late final ISpectLogger _logger;
  String? _result;

  @override
  void setup() {
    _logger = ISpectLogger(
      logger: ISpectBaseLogger(output: _LoggerBenchmark._discard),
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        maxHistoryItems: count,
      ),
    );
    for (var index = 0; index < count; index++) {
      _logger.info('Benchmark log $index', additionalData: _payload(1024));
    }
  }

  @override
  void exercise() {
    _result = switch (format) {
      _HistoryExportFormat.jsonLines =>
        LogExporter.toJsonLines(_logger.history),
      _HistoryExportFormat.text => LogExporter.toText(_logger.history),
    };
  }

  _BenchmarkResult result() => _BenchmarkResult(name, super.measure());

  @override
  void teardown() {
    _logger.dispose();
    if (_result == null) {
      throw StateError('Export history benchmark did not produce a result');
    }
  }
}

final class _CaptureBenchmark extends BenchmarkBase {
  _CaptureBenchmark(super.name, this.payload);

  final Map<String, Object?> payload;
  Object? _result;

  @override
  void exercise() {
    _result = ISpectLogData(
      'Benchmark event',
      key: 'info',
      additionalData: payload,
    );
  }

  _BenchmarkResult result() => _BenchmarkResult(name, super.measure());

  @override
  void teardown() {
    if (_result == null) {
      throw StateError('Capture benchmark did not produce a result');
    }
  }
}

final class _RedactionBenchmark extends BenchmarkBase {
  _RedactionBenchmark(super.name, this.payload);

  final Map<String, Object?> payload;
  late final RedactionService _redactor;
  Object? _result;

  @override
  void setup() {
    _redactor = RedactionService();
  }

  @override
  void exercise() {
    _result = _redactor.redact(payload);
  }

  _BenchmarkResult result() => _BenchmarkResult(name, super.measure());

  @override
  void teardown() {
    if (_result == null) {
      throw StateError('Redaction benchmark did not produce a result');
    }
  }
}

final class _ExportRedactionBenchmark extends BenchmarkBase {
  _ExportRedactionBenchmark(super.name, this.payload);

  final Map<String, Object?> payload;
  late final RedactionService _redactor;
  Object? _result;

  @override
  void setup() {
    _redactor = RedactionService();
  }

  @override
  void exercise() {
    _result = _redactor.redactForExport(payload);
  }

  _BenchmarkResult result() => _BenchmarkResult(name, super.measure());

  @override
  void teardown() {
    if (_result == null) {
      throw StateError('Export redaction benchmark did not produce a result');
    }
  }
}

final class _SnapshotBenchmark extends BenchmarkBase {
  _SnapshotBenchmark(super.name, this.payload);

  final Map<String, Object?> payload;
  Object? _result;

  @override
  void exercise() {
    _result = LogExportOutput.boundJsonValue(
      payload,
      preserveTypes: true,
      replaceOversizedStrings: true,
    );
  }

  _BenchmarkResult result() => _BenchmarkResult(name, super.measure());

  @override
  void teardown() {
    if (_result == null) {
      throw StateError('Snapshot benchmark did not produce a result');
    }
  }
}

final class _ExportBenchmark extends BenchmarkBase {
  _ExportBenchmark(
    super.name,
    this.logs, {
    this.enableRedaction = true,
  });

  final List<ISpectLogData> logs;
  final bool enableRedaction;
  String? _result;

  @override
  void exercise() {
    _result = LogExporter.toJsonLines(
      logs,
      redactKeys: const {'token'},
      enableRedaction: enableRedaction,
    );
  }

  _BenchmarkResult result() => _BenchmarkResult(name, super.measure());

  @override
  void teardown() {
    if (_result == null) {
      throw StateError('Export benchmark did not produce a result');
    }
  }
}

final class _BenchmarkResult {
  const _BenchmarkResult(this.name, this.microsecondsPerRun);

  final String name;
  final double microsecondsPerRun;

  Map<String, Object> toJson() => <String, Object>{
        'name': name,
        'microseconds-per-run': microsecondsPerRun,
      };
}
