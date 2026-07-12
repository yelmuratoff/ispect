String benchmarkReportMarkdown(
  Map<String, Object?> metrics, {
  required String commit,
  required DateTime generatedAt,
}) {
  final results = _results(metrics);
  final buffer = StringBuffer()
    ..writeln('# Latest benchmark results')
    ..writeln()
    ..writeln('- Commit: `$commit`')
    ..writeln('- Generated: `${generatedAt.toUtc().toIso8601String()}`')
    ..writeln('- OS: `${metrics['operating-system'] ?? 'unknown'}`')
    ..writeln('- Dart: `${metrics['dart-version'] ?? 'unknown'}`')
    ..writeln()
    ..writeln('| Benchmark | Microseconds per operation |')
    ..writeln('| --- | ---: |');

  for (final result in results) {
    buffer.writeln('| ${result['name']} | ${_formatDuration(result)} |');
  }

  final releaseSize = metrics['release-size'];
  if (releaseSize is Map<String, Object?>) {
    buffer
      ..writeln()
      ..writeln('## Android arm64 release footprint')
      ..writeln()
      ..writeln('| Variant | APK bytes |')
      ..writeln('| --- | ---: |')
      ..writeln('| Disabled | ${releaseSize['disabled-apk-bytes']} |')
      ..writeln('| Enabled | ${releaseSize['enabled-apk-bytes']} |');
  }

  return buffer.toString();
}

Map<String, Object> benchmarkBadge(Map<String, Object?> metrics) {
  final results = _results(metrics);
  final loggerResult = results.cast<Map<String, Object?>>().where(
        (result) => result['name'] == 'logger.metadata-only',
      );

  if (loggerResult.isEmpty) {
    return <String, Object>{
      'schemaVersion': 1,
      'label': 'benchmarks',
      'message': 'unavailable',
      'color': 'lightgrey',
    };
  }

  return <String, Object>{
    'schemaVersion': 1,
    'label': 'logger metadata',
    'message': '${_formatDuration(loggerResult.first)} µs/op',
    'color': 'blue',
  };
}

List<Map<String, Object?>> _results(Map<String, Object?> metrics) {
  final rawResults = metrics['results'];
  if (rawResults is! List<Object?>) return const <Map<String, Object?>>[];

  return rawResults
      .whereType<Map<Object?, Object?>>()
      .map(
        (result) => result.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      )
      .toList(growable: false);
}

String _formatDuration(Map<String, Object?> result) {
  final value = result['microseconds-per-run'];
  if (value is num) return value.toStringAsFixed(2);
  return 'unknown';
}
