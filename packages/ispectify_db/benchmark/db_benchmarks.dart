import 'dart:convert';
import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

void main(List<String> arguments) {
  final outputPath = _outputPath(arguments);
  final results = <_BenchmarkResult>[
    _DirectBenchmark().result(),
    _DbTraceBenchmark().result(),
  ];
  final report = <String, Object?>{
    'suite': 'ispectify-db',
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
  throw ArgumentError('Usage: db_benchmarks [--output <path>]');
}

final class _DirectBenchmark extends BenchmarkBase {
  _DirectBenchmark() : super('db.direct-operation');

  int _result = 0;

  @override
  void exercise() {
    _result = _query();
  }

  _BenchmarkResult result() => _BenchmarkResult(name, super.measure());

  @override
  void teardown() {
    if (_result != 1) throw StateError('Direct operation returned $_result');
  }
}

final class _DbTraceBenchmark extends BenchmarkBase {
  _DbTraceBenchmark() : super('db.trace-sync');

  late final ISpectLogger _logger;
  int _result = 0;

  @override
  void setup() {
    _logger = ISpectLogger(
      options: ISpectLoggerOptions(
        useConsoleLogs: false,
        maxHistoryItems: 1000,
      ),
    );
  }

  @override
  void exercise() {
    _result = _logger.dbTraceSync<int>(
      source: 'benchmark',
      operation: 'query',
      statement: 'SELECT id FROM entries WHERE status = ?',
      args: const <Object?>['active'],
      run: _query,
    );
  }

  _BenchmarkResult result() => _BenchmarkResult(name, super.measure());

  @override
  void teardown() {
    _logger.dispose();
    if (_result != 1) throw StateError('Traced operation returned $_result');
  }
}

int _query() => 1;

final class _BenchmarkResult {
  const _BenchmarkResult(this.name, this.microsecondsPerRun);

  final String name;
  final double microsecondsPerRun;

  Map<String, Object> toJson() => <String, Object>{
        'name': name,
        'microseconds-per-run': microsecondsPerRun,
      };
}
