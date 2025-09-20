import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/settings.dart';
import 'package:test/test.dart';

void main() {
  group('LoggerSettings', () {
    test('copyWith preserves enable=false when not overridden', () {
      final original = LoggerSettings(enable: false);
      final copy = original.copyWith(defaultTitle: 'New Title');

      expect(copy.enable, isFalse);
      expect(copy.defaultTitle, 'New Title');
    });

    test('copyWith allows overriding enable to true', () {
      final original = LoggerSettings(enable: false);
      final copy = original.copyWith(enable: true);

      expect(copy.enable, isTrue);
    });

    test('copyWith allows overriding enable to false', () {
      final original = LoggerSettings();
      final copy = original.copyWith(enable: false);

      expect(copy.enable, isFalse);
    });

    test('copyWith preserves all other fields when enable is changed', () {
      final original = LoggerSettings(
        defaultTitle: 'Original',
        level: LogLevel.warning,
        lineSymbol: '-',
        maxLineWidth: 100,
        enableColors: false,
      );
      final copy = original.copyWith(enable: false);

      expect(copy.enable, isFalse);
      expect(copy.defaultTitle, 'Original');
      expect(copy.level, LogLevel.warning);
      expect(copy.lineSymbol, '-');
      expect(copy.maxLineWidth, 100);
      expect(copy.enableColors, isFalse);
    });
  });
}
