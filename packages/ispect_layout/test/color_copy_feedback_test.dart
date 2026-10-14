import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/color_picker/color_picker_snackbar.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';

Widget _withoutMessenger(Widget child) => WidgetsApp(
  color: const Color(0xFF000000),
  builder: (context, _) => Center(child: child),
);

List<String?> _recordClipboard() {
  final copied = <String?>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied.add((call.arguments as Map?)?['text'] as String?);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return copied;
}

void main() {
  group('ColorHexChip', () {
    testWidgets('shows and copies the same hex the color picker reports', (
      tester,
    ) async {
      final copied = _recordClipboard();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: ColorHexChip(Color(0xFFAABBCC)))),
        ),
      );

      expect(find.text('#AABBCC'), findsOneWidget);

      await tester.tap(find.byType(ColorHexChip));
      await tester.pump();

      expect(copied, ['#AABBCC']);
    });

    testWidgets('copies without a ScaffoldMessenger in the tree', (
      tester,
    ) async {
      final copied = _recordClipboard();
      await tester.pumpWidget(
        _withoutMessenger(const ColorHexChip(Color(0x80AABBCC))),
      );

      await tester.tap(find.byType(ColorHexChip));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(copied, ['#80AABBCC']);
    });
  });

  group('showColorPickerResultSnackbar', () {
    testWidgets('is a no-op without a ScaffoldMessenger in the tree', (
      tester,
    ) async {
      const anchorKey = ValueKey('anchor');
      await tester.pumpWidget(
        _withoutMessenger(const SizedBox(key: anchorKey)),
      );

      showColorPickerResultSnackbar(
        context: tester.element(find.byKey(anchorKey)),
        color: const Color(0xFFAABBCC),
        showColorSchemeMatch: true,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
