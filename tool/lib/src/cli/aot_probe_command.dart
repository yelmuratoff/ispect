import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/aot_probe.dart';
import '../core/publish.dart';

/// Proves the pure-Dart packages tree-shake out of a build without
/// `ISPECT_ENABLED`, the local half of the CI release footprint check.
final class AotProbeCommand extends Command<int> {
  AotProbeCommand(this.repoRoot);

  final String repoRoot;

  @override
  String get name => 'aot-probe';

  @override
  String get description =>
      'Verify disabled AOT builds drop the ISpect sentinels the enabled build keeps.';

  @override
  Future<int> run() async {
    final scratch = Directory.systemTemp.createTempSync('ispect_aot_probe');
    try {
      final report = runAotProbe(
        repoRoot: repoRoot,
        scratch: scratch,
        runner: const SystemProcessRunner(),
        dartExecutable: Platform.resolvedExecutable,
      );
      for (final sentinel in report.retainedWhenDisabled) {
        stderr
            .writeln('[ERR] Disabled AOT retained ISpect sentinel: $sentinel');
      }
      for (final sentinel in report.missingWhenEnabled) {
        stderr.writeln('[ERR] Enabled control is missing sentinel: $sentinel');
      }
      if (!report.passed) {
        return 1;
      }
      stdout.writeln(
        '[OK ] ${aotProbeSentinels.length} sentinels absent when disabled, '
        'present when enabled',
      );
      return 0;
    } finally {
      scratch.deleteSync(recursive: true);
    }
  }
}
