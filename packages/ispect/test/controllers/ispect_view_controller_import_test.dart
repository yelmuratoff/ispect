import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';

void main() {
  test('reports records skipped by controller import', () async {
    final controller = ISpectViewController();
    addTearDown(controller.dispose);
    final content = jsonEncode({
      'logs': [
        {'message': 'Imported', 'time': DateTime.utc(2025).toIso8601String()},
        const {'invalid': true},
      ],
    });

    final result = await controller.importLogsFromJsonWithReport(content);

    expect(result.importedEntries, 1);
    expect(result.skippedEntries, 1);
    expect(result.hasSkippedEntries, isTrue);
  });

  test('updated settings immediately replace viewer diagnostic policies', () {
    final controller = ISpectViewController();
    addTearDown(controller.dispose);
    const maxImportCharacters = 64;
    final resourceLimits = DiagnosticResourceLimits.balanced.copyWith(
      maxImportCharacters: maxImportCharacters,
    );
    final processingPolicy = DiagnosticProcessingPolicy.balanced.copyWith(
      searchDebounce: const Duration(milliseconds: 25),
    );

    controller.updateSettings(
      controller.settings.copyWith(
        resourceLimits: resourceLimits,
        processingPolicy: processingPolicy,
      ),
    );

    expect(controller.resourceLimits, resourceLimits);
    expect(controller.processingPolicy, processingPolicy);
    expect(
      controller.validateLogsJsonContent('[${' ' * maxImportCharacters}]'),
      isFalse,
    );
  });
}
