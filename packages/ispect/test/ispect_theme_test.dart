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

    test('toMap / fromMap roundtrip preserves themeMode and useHostColors', () {
      const theme = ISpectTheme(
        themeMode: ISpectThemeMode.system,
        useHostColors: true,
      );

      final restored = ISpectTheme.fromMap(theme.toMap());

      expect(restored.themeMode, equals(ISpectThemeMode.system));
      expect(restored.useHostColors, isTrue);
    });

    test(
      'defaults to dark themeMode and owned colors (useHostColors false)',
      () {
        const theme = ISpectTheme();

        expect(theme.themeMode, equals(ISpectThemeMode.dark));
        expect(theme.useHostColors, isFalse);
      },
    );

    test('fromMap without theme keys defaults to dark and owned colors', () {
      final map = <String, dynamic>{'page_title': 'Legacy'};

      final theme = ISpectTheme.fromMap(map);

      expect(theme.themeMode, equals(ISpectThemeMode.dark));
      expect(theme.useHostColors, isFalse);
    });

    test('toMap / fromMap does not serialize icons (icons are code-only)', () {
      const theme = ISpectTheme(logIcons: {'http-request': Icons.cloud_upload});

      final map = theme.toMap();
      expect(map.containsKey('log_icons'), isFalse);

      final restored = ISpectTheme.fromMap(map);
      expect(restored.logIcons, isEmpty);
    });

    test('fromMap ignores legacy log_icons key without throwing', () {
      final map = <String, dynamic>{
        'page_title': 'Legacy',
        'log_icons': {'http-request': 0xe2c3},
      };

      final theme = ISpectTheme.fromMap(map);

      expect(theme.pageTitle, equals('Legacy'));
      expect(theme.logIcons, isEmpty);
    });

    test(
      'toMap / fromMap roundtrip preserves customLogTypes with all fields',
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
      },
    );

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
      expect(restored.logColors['my-event'], equals(const Color(0xFF7C4DFF)));
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
          },
        ],
      };

      final theme = ISpectTheme.fromMap(map);

      expect(theme.customLogTypes.first.level, equals(LogLevel.info));
    });
  });

  group('ISpectTheme.getTypeTitle', () {
    const theme = ISpectTheme(
      customLogTypes: [
        ISpectLogType('my-event', title: 'My Event'),
        ISpectLogType('http-request', title: 'Outbound Call'),
      ],
    );

    Future<BuildContext> pumpLocale(WidgetTester tester, Locale locale) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return captured;
    }

    testWidgets('resolves custom, built-in, and unknown keys per locale', (
      tester,
    ) async {
      for (final locale in const [Locale('en'), Locale('ru')]) {
        final context = await pumpLocale(tester, locale);

        expect(theme.getTypeTitle(context, key: 'my-event'), 'My Event');
        expect(
          theme.getTypeTitle(context, key: 'http-request'),
          'Outbound Call',
        );
        expect(theme.getTypeTitle(context, key: 'http-error'), 'HTTP Error');
        expect(theme.getTypeTitle(context, key: 'unknown-key'), 'unknown-key');
        expect(theme.getTypeTitle(context, key: ''), isNull);
        expect(theme.getTypeTitle(context, key: null), isNull);
      }
    });

    testWidgets('resolves titles again after the locale changes', (
      tester,
    ) async {
      final english = await pumpLocale(tester, const Locale('en'));
      final englishL10n = ISpectLocalization.of(english);
      final englishDescription = theme.getTypeDescription(
        english,
        key: 'bloc-event',
      );
      expect(theme.getTypeTitle(english, key: 'bloc-event'), 'BLoC Event');

      final russian = await pumpLocale(tester, const Locale('ru'));
      expect(ISpectLocalization.of(russian), isNot(same(englishL10n)));
      expect(theme.getTypeTitle(russian, key: 'bloc-event'), 'BLoC Event');
      expect(
        theme.getTypeDescription(russian, key: 'bloc-event'),
        isNot(englishDescription),
      );
    });
  });

  group('ISpectTheme.merge', () {
    const base = ISpectTheme(
      pageTitle: 'Base',
      themeMode: ISpectThemeMode.light,
      useHostColors: true,
      primary: ISpectDynamicColor(light: Colors.red, dark: Colors.red),
    );

    test('keeps colors the override leaves null', () {
      final merged = base.merge(const ISpectTheme());

      expect(merged.primary, base.primary);
    });

    test('takes defaulted scalars from the override', () {
      final merged = base.merge(const ISpectTheme());

      expect(merged.pageTitle, 'ISpect');
      expect(merged.themeMode, ISpectThemeMode.dark);
      expect(merged.useHostColors, isFalse);
    });
  });
}
