import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_http/ispectify_http.dart';

const _iterations = 1000;
const _warmupIterations = 100;
final _responseBody = jsonEncode(<String, Object>{
  'id': 'benchmark-response',
  'status': 'ok',
  'payload': 'x' * 1024,
});
final _benchmarkUri = Uri.parse('https://benchmark.invalid/benchmark');

Future<void> main(List<String> arguments) async {
  final outputPath = _outputPath(arguments);
  final results = <_BenchmarkResult>[
    await _measure('http.baseline', _baselineClient),
    await _measure('http.metadata-only', _metadataClient),
    await _measure('http.body-enabled', _bodyClient),
  ];
  final report = <String, Object?>{
    'suite': 'ispectify-http',
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
  throw ArgumentError('Usage: http_benchmarks [--output <path>]');
}

Future<_BenchmarkResult> _measure(
  String name,
  http.Client Function() createClient,
) async {
  final client = createClient();
  try {
    for (var index = 0; index < _warmupIterations; index++) {
      await client.get(_benchmarkUri);
    }

    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < _iterations; index++) {
      await client.get(_benchmarkUri);
    }
    stopwatch.stop();

    return _BenchmarkResult(
      name,
      stopwatch.elapsedMicroseconds / _iterations,
    );
  } finally {
    client.close();
  }
}

http.Client _baselineClient() => _mockClient();

http.Client _metadataClient() => _interceptedClient(
      const ISpectHttpInterceptorSettings(
        printRequestData: false,
        printResponseData: false,
      ),
    );

http.Client _bodyClient() => _interceptedClient(
      const ISpectHttpInterceptorSettings(
        printRequestData: true,
        printResponseData: true,
      ),
    );

InterceptedClient _interceptedClient(ISpectHttpInterceptorSettings settings) =>
    InterceptedClient.build(
      interceptors: <HttpInterceptor>[
        ISpectHttpInterceptor(
          logger: ISpectLogger(
            options: ISpectLoggerOptions(
              useConsoleLogs: false,
              useHistory: false,
            ),
          ),
          settings: settings,
        ),
      ],
      client: _mockClient(),
    );

http.Client _mockClient() => MockClient(
      (_) async => http.Response(
        _responseBody,
        HttpStatus.ok,
        headers: const <String, String>{'content-type': 'application/json'},
      ),
    );

final class _BenchmarkResult {
  const _BenchmarkResult(this.name, this.microsecondsPerRun);

  final String name;
  final double microsecondsPerRun;

  Map<String, Object> toJson() => <String, Object>{
        'name': name,
        'microseconds-per-run': microsecondsPerRun,
      };
}
