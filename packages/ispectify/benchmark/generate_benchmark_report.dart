import 'dart:convert';
import 'dart:io';

import 'benchmark_report.dart';

void main(List<String> arguments) {
  final options = _parseArguments(arguments);
  final input = File(options.inputPath);
  final decoded = jsonDecode(input.readAsStringSync());
  if (decoded is! Map<Object?, Object?>) {
    throw const FormatException('Benchmark input must be a JSON object');
  }

  final metrics = decoded.map(
    (key, value) => MapEntry(key.toString(), value),
  );
  for (final path in options.additionalInputPaths) {
    _appendResults(metrics, path);
  }
  final releaseSize = _releaseSize(options);
  if (releaseSize != null) metrics['release-size'] = releaseSize;

  final output = Directory(options.outputPath)..createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  File('${output.path}/metrics.json').writeAsStringSync(
    '${encoder.convert(metrics)}\n',
  );
  File('${output.path}/badge.json').writeAsStringSync(
    '${encoder.convert(benchmarkBadge(metrics))}\n',
  );
  File('${output.path}/report.md').writeAsStringSync(
    benchmarkReportMarkdown(
      metrics,
      commit: options.commit,
      generatedAt: DateTime.now().toUtc(),
    ),
  );
}

void _appendResults(Map<String, Object?> metrics, String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map<Object?, Object?>) {
    throw const FormatException('Additional benchmark input must be a JSON object');
  }
  final additionalResults = decoded['results'];
  if (additionalResults is! List<Object?>) {
    throw const FormatException('Additional benchmark input must contain results');
  }
  final results = metrics['results'];
  if (results is! List<Object?>) {
    throw const FormatException('Primary benchmark input must contain results');
  }
  results.addAll(additionalResults);
}

Map<String, int>? _releaseSize(_ReportOptions options) {
  if (options.disabledApkPath == null && options.enabledApkPath == null) {
    return null;
  }
  if (options.disabledApkPath == null || options.enabledApkPath == null) {
    throw ArgumentError(
      'Both APK paths are required for a release-size report',
    );
  }

  return <String, int>{
    'disabled-apk-bytes': File(options.disabledApkPath!).lengthSync(),
    'enabled-apk-bytes': File(options.enabledApkPath!).lengthSync(),
  };
}

_ReportOptions _parseArguments(List<String> arguments) {
  String? inputPath;
  String? outputPath;
  String? commit;
  String? disabledApkPath;
  String? enabledApkPath;
  final additionalInputPaths = <String>[];

  for (var index = 0; index < arguments.length; index += 2) {
    if (index + 1 >= arguments.length) break;
    switch (arguments[index]) {
      case '--input':
        inputPath = arguments[index + 1];
      case '--output':
        outputPath = arguments[index + 1];
      case '--additional-input':
        additionalInputPaths.add(arguments[index + 1]);
      case '--commit':
        commit = arguments[index + 1];
      case '--disabled-apk':
        disabledApkPath = arguments[index + 1];
      case '--enabled-apk':
        enabledApkPath = arguments[index + 1];
      default:
        throw ArgumentError('Unknown option: ${arguments[index]}');
    }
  }

  if (inputPath == null || outputPath == null || commit == null) {
    throw ArgumentError(
      'Usage: generate_benchmark_report --input <path> --output <path> '
      '--commit <sha> [--disabled-apk <path> --enabled-apk <path>]',
    );
  }

  return _ReportOptions(
    inputPath: inputPath,
    outputPath: outputPath,
    commit: commit,
    disabledApkPath: disabledApkPath,
    enabledApkPath: enabledApkPath,
    additionalInputPaths: additionalInputPaths,
  );
}

final class _ReportOptions {
  const _ReportOptions({
    required this.inputPath,
    required this.outputPath,
    required this.commit,
    required this.disabledApkPath,
    required this.enabledApkPath,
    required this.additionalInputPaths,
  });

  final String inputPath;
  final String outputPath;
  final String commit;
  final String? disabledApkPath;
  final String? enabledApkPath;
  final List<String> additionalInputPaths;
}
