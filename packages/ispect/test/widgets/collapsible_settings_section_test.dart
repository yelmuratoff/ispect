import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/action_tile.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/collapsible_settings_section.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/compact_toggle_grid.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/toggle_spec.dart';

import '../helpers/pump_ispect.dart';

void main() {
  group('CollapsibleSettingsSection', () {
    Future<void> pumpSection(WidgetTester tester) async {
      await tester.pumpWidget(
        appShell(
          const CollapsibleSettingsSection(
            title: 'Advanced',
            icon: Icons.settings_outlined,
            child: Text('History capacity'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    bool? expandedState(WidgetTester tester) => tester
        .widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.expanded != null,
          ),
        )
        .properties
        .expanded;

    testWidgets('starts collapsed and reveals its content on tap', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(find.text('History capacity'), findsNothing);
      expect(expandedState(tester), isFalse);

      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      expect(find.text('History capacity'), findsOneWidget);
      expect(expandedState(tester), isTrue);
    });

    testWidgets('announces its title once', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpSection(tester);

      expect(find.bySemanticsLabel('Advanced'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('settings rows semantics', () {
    testWidgets('a toggle row is one node with its title', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        appShell(
          CompactToggleRow(
            spec: ToggleSpec(
              title: 'Enabled',
              icon: Icons.power_settings_new_rounded,
              enabled: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Enabled'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('an action row reads its title and description once', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        appShell(
          ActionTile(
            action: ISpectActionItem(
              title: 'Import logs',
              icon: Icons.file_open_outlined,
              description: 'Open a saved log file',
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Import logs\nOpen a saved log file'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
