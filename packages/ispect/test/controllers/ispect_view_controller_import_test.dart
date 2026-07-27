import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';

void main() {
  test('reports records skipped by controller import', () async {
    final controller = ISpectViewController();
    addTearDown(controller.dispose);
    final content = jsonEncode({
      'logs': [
        {
          'message': 'Imported',
          'time': DateTime.utc(2025).toIso8601String(),
        },
        const {'invalid': true},
      ],
    });

    final result = await controller.importLogsFromJsonWithReport(content);

    expect(result.importedEntries, 1);
    expect(result.skippedEntries, 1);
    expect(result.hasSkippedEntries, isTrue);
  });
}
