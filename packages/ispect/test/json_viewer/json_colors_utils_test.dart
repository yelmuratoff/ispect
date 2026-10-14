import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/json_viewer/utils/colors.dart';

Future<Color> _colorFor(
  WidgetTester tester, {
  required String key,
  required Object? value,
  Brightness brightness = Brightness.light,
}) async {
  late Color color;
  await tester.pumpWidget(
    ISpectScopeController(
      model: ISpectScopeModel(isISpectEnabled: true),
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(
          builder: (context) {
            color = JsonColorsUtils.valueColorByKey(context, key, value);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return color;
}

void main() {
  group('JsonColorsUtils.valueColorByKey', () {
    testWidgets('colors the network status-code key by status class', (
      tester,
    ) async {
      final color = await _colorFor(
        tester,
        key: NetworkJsonKeys.statusCode,
        value: 404,
      );

      expect(color, JsonColors.statusColor(404));
    });

    testWidgets('colors the method key for the active brightness', (
      tester,
    ) async {
      final color = await _colorFor(
        tester,
        key: NetworkJsonKeys.method,
        value: 'get',
        brightness: Brightness.dark,
      );

      expect(color, JsonColors.methodColorFor('GET', Brightness.dark));
    });
  });
}
