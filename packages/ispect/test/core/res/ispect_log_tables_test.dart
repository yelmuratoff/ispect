import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

import '../../helpers/pump_ispect.dart';

void main() {
  final builtInKeys = ISpectLogType.builtIn.map((t) => t.key).toList();

  test('every built-in log type has an icon', () {
    final missing = builtInKeys.where(
      (k) => !ISpectConstants.typeIcons.containsKey(k),
    );

    expect(missing, isEmpty);
  });

  test('every built-in log type has light and dark colors', () {
    final missingLight = builtInKeys.where(
      (k) => !ISpectConstants.lightTypeColors.containsKey(k),
    );
    final missingDark = builtInKeys.where(
      (k) => !ISpectConstants.darkTypeColors.containsKey(k),
    );

    expect(missingLight, isEmpty);
    expect(missingDark, isEmpty);
  });

  test('icon and color tables hold only built-in log types', () {
    for (final table in [
      ISpectConstants.typeIcons,
      ISpectConstants.lightTypeColors,
      ISpectConstants.darkTypeColors,
    ]) {
      expect(table.keys.toSet(), builtInKeys.toSet());
    }
  });

  test('icon and color tables reject mutation', () {
    expect(
      () => ISpectConstants.typeIcons['custom'] = Icons.abc,
      throwsUnsupportedError,
    );
    expect(
      () => ISpectConstants.lightTypeColors['custom'] = Colors.red,
      throwsUnsupportedError,
    );
    expect(
      () => ISpectConstants.darkTypeColors['custom'] = Colors.red,
      throwsUnsupportedError,
    );
  });

  testWidgets('every built-in log type has a description', (tester) async {
    await tester.pumpWidget(appShell(const SizedBox.shrink()));
    final context = tester.element(find.byType(SizedBox));

    final described = ISpectConstants.defaultLogDescriptions(
      context,
    ).map((d) => d.key).toSet();
    final missing = builtInKeys.where((k) => !described.contains(k));

    expect(missing, isEmpty);
  });
}
