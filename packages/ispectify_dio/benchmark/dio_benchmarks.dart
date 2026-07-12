import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';

const _iterations = 1000;
const _warmupIterations = 100;
final _responseBytes = Uint8List.fromList(
  utf8.encode(
    jsonEncode(<String, Object>{
      'id': 'benchmark-response',
      'status': 'ok',
      'payload': 'x' * 1024,
    }),
  ),
);

Future<void> main(List<String> arguments) async {
  final outputPath = _outputPath(arguments);
  final results = <_BenchmarkResult>[
    await _measure('dio.baseline', _baselineClient),
    await _measure('dio.metadata-only', _metadataClient),
    await _measure('dio.body-enabled', _bodyClient),
  ];
  final report = <String, Object?>{
    'suite': 'ispectify-dio',
    'dart-version': Platform.version,
    'operating-system': Platform.operatingSystem,
    'iterations-per-result': _iterations,
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
  throw ArgumentError('Usage: dio_benchmarks [--output <path>]');
}

Future<_BenchmarkResult> _measure(
  String name,
  Dio Function() createClient,
) async {
  final client = createClient();
  try {
    for (var index = 0; index < _warmupIterations; index++) {
      await client.get<dynamic>('/benchmark');
    }

    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < _iterations; index++) {
      await client.get<dynamic>('/benchmark');
    }
    stopwatch.stop();

    return _BenchmarkResult(
      name,
      stopwatch.elapsedMicroseconds / _iterations,
    );
  } finally {
    client.close(force: true);
  }
}

Dio _baselineClient() => _client();

Dio _metadataClient() => _client(
      settings: const ISpectDioInterceptorSettings(
        printRequestData: false,
        printResponseData: false,
      ),
    );

Dio _bodyClient() => _client(
      settings: const ISpectDioInterceptorSettings(
        printRequestData: true,
        printResponseData: true,
      ),
    );

Dio _client({ISpectDioInterceptorSettings? settings}) {
  final client = Dio(BaseOptions(baseUrl: 'https://benchmark.invalid'))
    ..httpClientAdapter = _BenchmarkHttpAdapter();
  if (settings != null) {
    client.interceptors.add(
      ISpectDioInterceptor(
        logger: ISpectLogger(
          options: ISpectLoggerOptions(
            useConsoleLogs: false,
            useHistory: false,
          ),
        ),
        settings: settings,
      ),
    );
  }
  return client;
}

final class _BenchmarkHttpAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromBytes(
        _responseBytes,
        HttpStatus.ok,
        headers: const <String, List<String>>{
          Headers.contentTypeHeader: <String>['application/json'],
        },
      );

  @override
  void close({bool force = false}) {}
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
