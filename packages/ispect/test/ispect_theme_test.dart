import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';

void main() {
  group('ISpectTheme serialization', () {
    test('toMap / fromMap roundtrip preserves scalar and color fields', () {
      const theme = ISpectTheme(
        pageTitle: 'Test Inspector',
        background: ISpectDynamicColor(
          dark: Color(0xFF121212),
          light: Color(0xFFFFFFFF),
        ),
        logColors: {'http-request': Color(0xFFFF5252)},
        logDescriptions: {'http-request': 'HTTP request'},
        categoryLabels: {'network': 'HTTP'},
        logCategories: {'my-log': 'network'},
      );

      final restored = ISpectTheme.fromMap(theme.toMap());

      expect(restored.pageTitle, equals(theme.pageTitle));
      expect(restored.background?.dark, equals(theme.background?.dark));
      expect(restored.background?.light, equals(theme.background?.light));
      expect(
        restored.logColors['http-request'],
        equals(const Color(0xFFFF5252)),
      );
      expect(restored.logDescriptions, equals(theme.logDescriptions));
      expect(restored.categoryLabels, equals(theme.categoryLabels));
      expect(restored.logCategories, equals(theme.logCategories));
    });

    test('toMap / fromMap roundtrip preserves icons', () {
      const theme = ISpectTheme(
        logIcons: {'http-request': Icons.cloud_upload},
      );

      final restored = ISpectTheme.fromMap(theme.toMap());

      expect(
        restored.logIcons['http-request']?.codePoint,
        equals(Icons.cloud_upload.codePoint),
      );
    });

    test('toMap / fromMap roundtrip preserves customLogTypes with all fields',
        () {
      const custom = ISpectLogType(
        'firebase-read',
        category: 'firebase',
        level: LogLevel.debug,
        title: 'Firebase Read',
      );
      const customError = ISpectLogType(
        'firebase-error',
        category: 'firebase',
        isError: true,
        level: LogLevel.error,
      );
      const theme = ISpectTheme(
        customLogTypes: [custom, customError],
        logColors: {
          'firebase-read': Color(0xFFFFA000),
          'firebase-error': Color(0xFFD50000),
        },
      );

      final restored = ISpectTheme.fromMap(theme.toMap());

      expect(restored.customLogTypes.length, equals(2));

      final r1 = restored.customLogTypes[0];
      expect(r1.key, equals('firebase-read'));
      expect(r1.category, equals('firebase'));
      expect(r1.isError, isFalse);
      expect(r1.level, equals(LogLevel.debug));
      expect(r1.title, equals('Firebase Read'));

      final r2 = restored.customLogTypes[1];
      expect(r2.key, equals('firebase-error'));
      expect(r2.isError, isTrue);
      expect(r2.level, equals(LogLevel.error));
      expect(r2.title, isNull);
    });

    test('toMap / fromMap with no customLogTypes returns empty list', () {
      const theme = ISpectTheme(pageTitle: 'No customs');

      final restored = ISpectTheme.fromMap(theme.toMap());

      expect(restored.customLogTypes, isEmpty);
    });

    test('fromMap without custom_log_types key returns empty list', () {
      final map = <String, dynamic>{
        'page_title': 'Old format',
        'log_colors': null,
        'log_icons': null,
        'log_descriptions': null,
        'category_labels': null,
        'log_categories': null,
      };

      final theme = ISpectTheme.fromMap(map);

      expect(theme.customLogTypes, isEmpty);
      expect(theme.pageTitle, equals('Old format'));
    });

    test('toJson / fromJson roundtrip', () {
      const custom = ISpectLogType(
        'my-event',
        category: 'analytics',
        title: 'My Event',
      );
      const theme = ISpectTheme(
        pageTitle: 'JSON Test',
        customLogTypes: [custom],
        logColors: {'my-event': Color(0xFF7C4DFF)},
      );

      final restored = ISpectTheme.fromJson(theme.toJson());

      expect(restored.pageTitle, equals('JSON Test'));
      expect(restored.customLogTypes.length, equals(1));
      expect(restored.customLogTypes.first.key, equals('my-event'));
      expect(restored.customLogTypes.first.title, equals('My Event'));
      expect(
        restored.logColors['my-event'],
        equals(const Color(0xFF7C4DFF)),
      );
    });

    test('customLogType with unknown level falls back to LogLevel.info', () {
      final map = <String, dynamic>{
        'page_title': null,
        'log_colors': null,
        'log_icons': null,
        'log_descriptions': null,
        'category_labels': null,
        'log_categories': null,
        'custom_log_types': [
          {
            'key': 'test-key',
            'category': 'general',
            'is_error': false,
            'level': 'nonexistent_level',
          }
        ],
      };

      final theme = ISpectTheme.fromMap(map);

      expect(theme.customLogTypes.first.level, equals(LogLevel.info));
    });
  });
}
