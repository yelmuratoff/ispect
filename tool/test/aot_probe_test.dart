@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:ispect_tool/src/core/aot_probe.dart';
import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/publish.dart';
import 'package:ispect_tool/src/core/repo_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Writes a fake snapshot holding [disabled] or [enabled] for each compile.
final class _SnapshotWriter implements ProcessRunner {
  _SnapshotWriter({
    required this.disabled,
    required this.enabled,
    this.failCompile = false,
  });

  final List<String> disabled;
  final List<String> enabled;
  final bool failCompile;
  final List<List<String>> calls = [];

  @override
  CommandResult run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) {
    calls.add(arguments);
    if (arguments.first != 'compile') {
      return const CommandResult(exitCode: 0, output: '');
    }
    if (failCompile) {
      return const CommandResult(exitCode: 254, output: 'Error: boom\n');
    }
    final output = arguments[arguments.indexOf('-o') + 1];
    final strings =
        arguments.contains('-DISPECT_ENABLED=true') ? enabled : disabled;
    File(output).writeAsBytesSync([
      0,
      1,
      2,
      255,
      ...latin1.encode(strings.join('\u0000')),
      254,
      0,
    ]);
    return const CommandResult(exitCode: 0, output: '');
  }
}

void main() {
  group('sentinelsIn', () {
    test('finds sentinels embedded among non-text bytes', () {
      final snapshot = [
        0,
        200,
        ...latin1.encode('xx bloc_event_ids yy'),
        7,
        255,
      ];

      expect(
        sentinelsIn(snapshot, const ['bloc_event_ids', 'provider-name']),
        ['bloc_event_ids'],
      );
    });
  });

  group('runAotProbe', () {
    late Directory scratch;

    setUp(() {
      scratch = Directory.systemTemp.createTempSync('aot_probe_test');
    });

    tearDown(() {
      scratch.deleteSync(recursive: true);
    });

    AotProbeReport probe(_SnapshotWriter runner) => runAotProbe(
          repoRoot: '/repo',
          scratch: scratch,
          runner: runner,
          dartExecutable: 'dart',
        );

    test('passes when only the enabled build holds the sentinels', () {
      final runner = _SnapshotWriter(
        disabled: const ['main'],
        enabled: aotProbeSentinels,
      );

      final report = probe(runner);

      expect(report.passed, isTrue);
      expect(runner.calls.first, ['pub', 'get']);
      expect(
        runner.calls.where((call) => call.contains('-DISPECT_ENABLED=true')),
        hasLength(1),
      );
    });

    test('names a sentinel the disabled build retains', () {
      final report = probe(
        _SnapshotWriter(
          disabled: const ['bloc_event_ids'],
          enabled: aotProbeSentinels,
        ),
      );

      expect(report.passed, isFalse);
      expect(report.retainedWhenDisabled, ['bloc_event_ids']);
      expect(report.missingWhenEnabled, isEmpty);
    });

    test('names a sentinel the enabled control no longer reaches', () {
      final report = probe(
        _SnapshotWriter(
          disabled: const [],
          enabled: aotProbeSentinels.where((s) => s != 'ispect_sw').toList(),
        ),
      );

      expect(report.passed, isFalse);
      expect(report.missingWhenEnabled, ['ispect_sw']);
    });

    test('throws when a compile fails', () {
      expect(
        () => probe(
          _SnapshotWriter(
            disabled: const [],
            enabled: const [],
            failCompile: true,
          ),
        ),
        throwsA(
          isA<AotProbeException>().having(
            (e) => e.message,
            'message',
            contains('boom'),
          ),
        ),
      );
    });
  });

  test('every local sentinel is one the CI footprint check enforces', () {
    final repoRoot = findRepoRoot(Directory.current.path)!;
    final workflow = File(
      p.join(repoRoot, '.github', 'workflows', 'production_safety.yml'),
    ).readAsStringSync();

    for (final sentinel in aotProbeSentinels) {
      expect(workflow, contains('"$sentinel"'), reason: sentinel);
    }
  });
}
