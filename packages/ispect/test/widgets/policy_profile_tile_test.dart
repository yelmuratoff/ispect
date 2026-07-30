import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/policy_profile_tile.dart';

import '../helpers/pump_ispect.dart';

void main() {
  testWidgets('applies a selected diagnostic profile', (tester) async {
    String? selected;
    await tester.pumpWidget(
      appShell(
        PolicyProfileTile<String>(
          label: 'Resource profile',
          description: 'Capture and handoff budgets',
          icon: Icons.memory_rounded,
          value: 'balanced',
          options: const [
            PolicyProfileOption(
              label: 'Constrained',
              description: 'Smaller memory footprint',
              value: 'constrained',
            ),
            PolicyProfileOption(
              label: 'Balanced',
              description: 'Useful diagnostics with safe bounds',
              value: 'balanced',
            ),
          ],
          onChanged: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.text('Resource profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Constrained').last);
    await tester.pumpAndSettle();

    expect(selected, 'constrained');
  });
}
