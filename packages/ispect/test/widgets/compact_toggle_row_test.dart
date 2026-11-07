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

  group('CompactToggleRow switch direction', () {
    Future<({Rect track, Rect thumb})> pumpSwitch(
      WidgetTester tester, {
      required Locale locale,
      required bool enabled,
    }) async {
      await tester.pumpWidget(
        appShell(
          locale: locale,
          CompactToggleRow(
            spec: ToggleSpec(
              title: 'Console logs',
              icon: Icons.terminal_rounded,
              enabled: enabled,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final thumb = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      );
      final track = find.ancestor(of: thumb, matching: find.byType(Stack));
      return (track: tester.getRect(track.first), thumb: tester.getRect(thumb));
    }

    for (final (languageCode, onSideIsRight) in [('en', true), ('ar', false)]) {
      testWidgets('the thumb moves toward the end edge in $languageCode', (
        tester,
      ) async {
        final off = await pumpSwitch(
          tester,
          locale: Locale(languageCode),
          enabled: false,
        );
        final on = await pumpSwitch(
          tester,
          locale: Locale(languageCode),
          enabled: true,
        );

        expect(on.track, off.track);
        expect(
          on.thumb.center.dx > off.thumb.center.dx,
          onSideIsRight,
          reason: 'on=${on.thumb} off=${off.thumb}',
        );
      });
    }
  });
}
