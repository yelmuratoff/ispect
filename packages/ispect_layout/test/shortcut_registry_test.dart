import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/shortcut_registry.dart';

InspectorShortcuts _shortcuts({
  List<ShortcutActivator>? inspector,
  List<LogicalKeyboardKey>? inspectorLegacy,
  List<LogicalKeyboardKey>? compareLegacy,
  List<ShortcutActivator>? colorPicker,
  List<LogicalKeyboardKey>? colorPickerLegacy,
}) => InspectorShortcuts(
  inspectorActivators: inspector,
  inspectorLegacyKeys: inspectorLegacy,
  compareActivators: null,
  compareLegacyKeys: compareLegacy,
  colorPickerActivators: colorPicker,
  colorPickerLegacyKeys: colorPickerLegacy,
  zoomActivators: null,
  zoomLegacyKeys: null,
);

Matcher _nonRepeating(LogicalKeyboardKey trigger) => isA<SingleActivator>()
    .having((a) => a.trigger, 'trigger', trigger)
    .having((a) => a.includeRepeats, 'includeRepeats', isFalse)
    .having(
      (a) => a.alt || a.control || a.meta || a.shift,
      'modifiers',
      isFalse,
    );

final class _TriggerActivator extends ShortcutActivator {
  const _TriggerActivator(this.keys);

  final List<LogicalKeyboardKey> keys;

  @override
  Iterable<LogicalKeyboardKey> get triggers => keys;

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      event is KeyDownEvent && keys.every(state.logicalKeysPressed.contains);

  @override
  String debugDescribeKeys() => keys.join('+');
}

void main() {
  group('InspectorShortcuts resolution', () {
    test('falls back to Alt-based defaults', () {
      final shortcuts = _shortcuts();

      expect(shortcuts.effectiveInspectorActivators, const [
        SingleActivator(
          LogicalKeyboardKey.keyW,
          alt: true,
          includeRepeats: false,
        ),
      ]);
      expect(shortcuts.effectiveCompareActivators, const [
        SingleActivator(
          LogicalKeyboardKey.keyY,
          alt: true,
          includeRepeats: false,
        ),
      ]);
      expect(shortcuts.effectiveColorPickerActivators, const [
        SingleActivator(
          LogicalKeyboardKey.keyC,
          alt: true,
          includeRepeats: false,
        ),
      ]);
      expect(shortcuts.effectiveZoomActivators, const [
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          alt: true,
          includeRepeats: false,
        ),
      ]);
    });

    test('explicit activators win over legacy keys', () {
      const explicit = SingleActivator(LogicalKeyboardKey.keyI, control: true);
      final shortcuts = _shortcuts(
        inspector: const [explicit],
        inspectorLegacy: const [LogicalKeyboardKey.keyQ],
      );

      expect(shortcuts.effectiveInspectorActivators, const [explicit]);
    });

    test('explicit activators are exposed read-only', () {
      final shortcuts = _shortcuts(
        inspector: [const SingleActivator(LogicalKeyboardKey.keyI)],
      );

      expect(
        () => shortcuts.effectiveInspectorActivators.add(
          const SingleActivator(LogicalKeyboardKey.keyJ),
        ),
        throwsUnsupportedError,
      );
    });

    test('legacy hold keys map modifiers to key sets and others to '
        'non-repeating single activators', () {
      final shortcuts = _shortcuts(
        inspectorLegacy: const [
          LogicalKeyboardKey.altLeft,
          LogicalKeyboardKey.keyQ,
        ],
      );

      final activators = shortcuts.effectiveInspectorActivators;
      expect(activators.first, isA<LogicalKeySet>());
      expect(activators.last, _nonRepeating(LogicalKeyboardKey.keyQ));
    });

    test('legacy compare keys map to non-repeating single activators', () {
      final shortcuts = _shortcuts(
        compareLegacy: const [LogicalKeyboardKey.keyQ],
      );

      expect(shortcuts.effectiveCompareActivators, [
        _nonRepeating(LogicalKeyboardKey.keyQ),
      ]);
    });

    test('legacy compare modifier keys resolve without a SingleActivator', () {
      final shortcuts = _shortcuts(
        compareLegacy: const [LogicalKeyboardKey.shiftLeft],
      );

      final activators = shortcuts.effectiveCompareActivators;

      expect(activators, hasLength(1));
      expect(activators.single, isNot(isA<SingleActivator>()));
      expect(activators.single.triggers, [LogicalKeyboardKey.shiftLeft]);
    });
  });

  group('InspectorShortcuts still-pressed', () {
    testWidgets('a single activator needs its exact modifiers held', (
      tester,
    ) async {
      final shortcuts = _shortcuts();
      final keyboard = HardwareKeyboard.instance;

      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
      expect(shortcuts.inspectorStillPressed(keyboard), isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      expect(shortcuts.inspectorStillPressed(keyboard), isFalse);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
      expect(shortcuts.inspectorStillPressed(keyboard), isFalse);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
    });

    testWidgets('a legacy modifier key set matches either side', (
      tester,
    ) async {
      final shortcuts = _shortcuts(
        colorPickerLegacy: const [LogicalKeyboardKey.altLeft],
      );
      final keyboard = HardwareKeyboard.instance;

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altRight);
      expect(shortcuts.colorPickerStillPressed(keyboard), isTrue);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.altRight);
      expect(shortcuts.colorPickerStillPressed(keyboard), isFalse);
    });

    testWidgets('a custom activator stays pressed while all its triggers are '
        'down', (tester) async {
      final shortcuts = _shortcuts(
        colorPicker: const [
          _TriggerActivator([LogicalKeyboardKey.keyP, LogicalKeyboardKey.keyK]),
        ],
      );
      final keyboard = HardwareKeyboard.instance;

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
      expect(shortcuts.colorPickerStillPressed(keyboard), isTrue);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
      expect(shortcuts.colorPickerStillPressed(keyboard), isFalse);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
    });
  });

  group('InspectorShortcuts accepts', () {
    testWidgets('matches the configured activator only', (tester) async {
      final shortcuts = _shortcuts();
      final keyboard = HardwareKeyboard.instance;
      final accepted = <String>[];
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        Focus(
          focusNode: focusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (shortcuts.acceptsInspector(event, keyboard)) {
              accepted.add('inspector');
            }
            if (shortcuts.acceptsColorPicker(event, keyboard)) {
              accepted.add('colorPicker');
            }
            return KeyEventResult.ignored;
          },
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);

      expect(accepted, ['colorPicker']);
    });

    testWidgets('a legacy compare modifier key toggles once per press', (
      tester,
    ) async {
      final shortcuts = _shortcuts(
        compareLegacy: const [LogicalKeyboardKey.shiftLeft],
      );
      final keyboard = HardwareKeyboard.instance;
      final accepted = <KeyEvent>[];
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        Focus(
          focusNode: focusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (shortcuts.acceptsCompare(event, keyboard)) {
              accepted.add(event);
            }
            return KeyEventResult.ignored;
          },
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(accepted, [isA<KeyDownEvent>()]);
    });
  });
}
