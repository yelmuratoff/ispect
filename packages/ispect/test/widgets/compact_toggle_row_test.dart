import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/compact_toggle_grid.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/toggle_spec.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('CompactToggleRow semantics', () {
    Future<void> pumpRow(WidgetTester tester, {required bool canEdit}) =>
        tester.pumpWidget(
          appShell(
            CompactToggleRow(
              spec: ToggleSpec(
                title: 'Console logs',
                icon: Icons.terminal_rounded,
                enabled: true,
                canEdit: canEdit,
                onChanged: (_) {},
              ),
            ),
          ),
        );

    testWidgets('an editable toggle is announced as enabled', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpRow(tester, canEdit: true);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Console logs')),
        matchesSemantics(
          label: 'Console logs',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('a locked toggle is announced as disabled', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpRow(tester, canEdit: false);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Console logs')),
        matchesSemantics(
          label: 'Console logs',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
        ),
      );
      semantics.dispose();
    });
  });
}
