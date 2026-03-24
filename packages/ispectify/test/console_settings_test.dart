import 'package:ispectify/src/console_settings.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:test/test.dart';

void main() {
  group('ConsoleSettings', () {
    test('copyWith preserves enable=false when not overridden', () {
      final original = ConsoleSettings(enabled: false);
      final copy = original.copyWith(defaultTitle: 'New Title');

      expect(copy.enabled, isFalse);
      expect(copy.defaultTitle, 'New Title');
    });

    test('copyWith allows overriding enable to true', () {
      final original = ConsoleSettings(enabled: false);
      final copy = original.copyWith(enabled: true);

      expect(copy.enabled, isTrue);
    });

    test('copyWith allows overriding enable to false', () {
      final original = ConsoleSettings();
      final copy = original.copyWith(enabled: false);

      expect(copy.enabled, isFalse);
    });

    test('copyWith preserves all other fields when enable is changed', () {
      final original = ConsoleSettings(
        defaultTitle: 'Original',
        level: LogLevel.warning,
        lineSymbol: '-',
        maxLineWidth: 100,
        enableColors: false,
      );
      final copy = original.copyWith(enabled: false);

      expect(copy.enabled, isFalse);
      expect(copy.defaultTitle, 'Original');
      expect(copy.level, LogLevel.warning);
      expect(copy.lineSymbol, '-');
      expect(copy.maxLineWidth, 100);
      expect(copy.enableColors, isFalse);
    });
  });
}
