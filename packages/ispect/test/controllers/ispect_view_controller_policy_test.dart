import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';

void main() {
  test('updated settings immediately replace viewer diagnostic policies', () {
    final controller = ISpectViewController();
    addTearDown(controller.dispose);
    final resourceLimits = DiagnosticResourceLimits.balanced.copyWith(
      maxImportCharacters: 64,
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
    expect(controller.filter.resourceLimits, resourceLimits);
  });
}
