import 'package:test/test.dart';

import '../benchmark/benchmark_report.dart';

void main() {
  final metrics = <String, Object?>{
    'operating-system': 'linux',
    'dart-version': '3.6.0',
    'results': <Object?>[
      <String, Object?>{
        'name': 'logger.metadata-only',
        'microseconds-per-run': 1.234,
      },
    ],
  };

  test('renders measured benchmark values into the report', () {
    final report = benchmarkReportMarkdown(
      metrics,
      commit: 'abc123',
      generatedAt: DateTime.utc(2026),
    );

    expect(report, contains('`abc123`'));
    expect(report, contains('| logger.metadata-only | 1.23 |'));
  });

  test('creates a Shields endpoint from the metadata-only result', () {
    expect(
      benchmarkBadge(metrics),
      <String, Object>{
        'schemaVersion': 1,
        'label': 'logger metadata',
        'message': '1.23 µs/op',
        'color': 'blue',
      },
    );
  });
}
