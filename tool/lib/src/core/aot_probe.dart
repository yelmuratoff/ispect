import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'exceptions.dart';
import 'publish.dart';

/// Strings that only ISpect implementation code holds, one or more per
/// pure-Dart package the probe exercises.
///
/// A subset of the sentinels in `.github/workflows/production_safety.yml`; the
/// Flutter UI sentinels need the release APK that only CI builds.
const List<String> aotProbeSentinels = [
  'statementDigest',
  '_ispect_started_at',
  'ispect_sw',
  'ISpect WebSocket frame capture failed safely.',
  'bloc_event_ids',
  'provider-name',
];

/// Repository-relative package that holds the probe program.
const String aotProbeDirectory = 'packages/ispect/example';

/// Package-relative path of the pure-Dart probe; the CI release probe calls
/// the same function before it starts the Flutter app.
const String aotProbeTarget = 'lib/production_safety_diagnostics.dart';

/// What the sentinel scan found in the disabled and enabled snapshots.
final class AotProbeReport {
  const AotProbeReport({
    required this.retainedWhenDisabled,
    required this.missingWhenEnabled,
  });

  /// Sentinels a build without `ISPECT_ENABLED` still holds.
  final List<String> retainedWhenDisabled;

  /// Sentinels the enabled control lacks, which means the probe no longer
  /// reaches the code they guard.
  final List<String> missingWhenEnabled;

  bool get passed => retainedWhenDisabled.isEmpty && missingWhenEnabled.isEmpty;
}

/// The members of [sentinels] whose bytes occur in [snapshot].
List<String> sentinelsIn(List<int> snapshot, Iterable<String> sentinels) {
  final text = latin1.decode(snapshot);
  return [
    for (final sentinel in sentinels)
      if (text.contains(sentinel)) sentinel,
  ];
}

/// Compiles the probe in [repoRoot] to AOT snapshots with and without
/// `ISPECT_ENABLED` under [scratch], and scans both for [sentinels].
///
/// Throws [AotProbeException] when resolving or compiling the probe fails.
AotProbeReport runAotProbe({
  required String repoRoot,
  required Directory scratch,
  required ProcessRunner runner,
  required String dartExecutable,
  List<String> sentinels = aotProbeSentinels,
}) {
  final probe = p.join(repoRoot, aotProbeDirectory);

  final resolved = runner.run(
    dartExecutable,
    const ['pub', 'get'],
    workingDirectory: probe,
  );
  if (!resolved.succeeded) {
    throw AotProbeException(
      'dart pub get failed in $aotProbeDirectory\n${resolved.output}',
    );
  }

  List<int> compile({required bool enabled}) {
    final variant = enabled ? 'enabled' : 'disabled';
    final output = p.join(scratch.path, '$variant.aot');
    final compiled = runner.run(
      dartExecutable,
      [
        'compile',
        'aot-snapshot',
        if (enabled) '-DISPECT_ENABLED=true',
        aotProbeTarget,
        '-o',
        output,
      ],
      workingDirectory: probe,
    );
    if (!compiled.succeeded) {
      throw AotProbeException(
        'Compiling the $variant probe failed\n${compiled.output}',
      );
    }
    return File(output).readAsBytesSync();
  }

  final retained = sentinelsIn(compile(enabled: false), sentinels);
  final present = sentinelsIn(compile(enabled: true), sentinels);
  return AotProbeReport(
    retainedWhenDisabled: retained,
    missingWhenEnabled: [
      for (final sentinel in sentinels)
        if (!present.contains(sentinel)) sentinel,
    ],
  );
}
