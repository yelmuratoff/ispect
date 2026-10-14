import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectMetadata.toMap', () {
    test('omits null typed fields', () {
      const metadata = ISpectMetadata(appVersion: '1.2.3', os: 'iOS');

      expect(metadata.toMap(), {'appVersion': '1.2.3', 'os': 'iOS'});
    });

    test('is empty when nothing is set', () {
      const metadata = ISpectMetadata();

      expect(metadata.toMap(), isEmpty);
      expect(metadata.isEmpty, isTrue);
    });

    test('merges extra entries alongside typed fields', () {
      const metadata = ISpectMetadata(
        appVersion: '1.0.0',
        extra: {'flavor': 'qa'},
      );

      expect(metadata.toMap(), {'appVersion': '1.0.0', 'flavor': 'qa'});
    });

    test('typed fields take precedence over extra on key collision', () {
      const metadata = ISpectMetadata(
        appVersion: '2.0.0',
        extra: {'appVersion': 'stale'},
      );

      expect(metadata.toMap()['appVersion'], '2.0.0');
    });
  });

  group('ISpectMetadata equality', () {
    test('equal instances compare equal with matching extra maps', () {
      const a = ISpectMetadata(appVersion: '1.0.0', extra: {'k': 'v'});
      const b = ISpectMetadata(appVersion: '1.0.0', extra: {'k': 'v'});

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith overrides only the provided fields', () {
      const base = ISpectMetadata(appVersion: '1.0.0', os: 'iOS');

      expect(base.copyWith(os: 'Android').toMap(), {
        'appVersion': '1.0.0',
        'os': 'Android',
      });
    });
  });

  group('LogExporter metadata header', () {
    final logs = [ISpectLogData('hello', key: 'INFO')];

    test('toText renders each metadata field as a key: value line', () {
      final output = LogExporter.toText(
        logs,
        metadata: const ISpectMetadata(appVersion: '1.2.3', os: 'iOS'),
      );

      expect(output, contains('appVersion: 1.2.3'));
      expect(output, contains('os: iOS'));
    });

    test('toText without metadata keeps the original header', () {
      final output = LogExporter.toText(logs);

      expect(output, contains('=== ISpect Log Report ==='));
      expect(output, isNot(contains('appVersion')));
    });

    test('toMarkdown renders metadata as blockquote lines', () {
      final output = LogExporter.toMarkdown(
        logs,
        metadata: const ISpectMetadata(appVersion: '1.2.3'),
      );

      expect(output, contains('> appVersion: 1.2.3'));
    });

    group('every typed field', () {
      const full = ISpectMetadata(
        appName: 'Demo',
        appVersion: '1.2.3',
        buildNumber: '42',
        environment: 'staging',
        device: 'Pixel 8',
        os: 'Android',
        osVersion: '14',
        locale: 'en_US',
        extra: {'flavor': 'qa', 'appVersion': 'stale'},
      );
      final typedKeys = const ISpectMetadata(
        appName: 'Demo',
        appVersion: '1.2.3',
        buildNumber: '42',
        environment: 'staging',
        device: 'Pixel 8',
        os: 'Android',
        osVersion: '14',
        locale: 'en_US',
      ).toMap();

      test('covers all eight typed fields', () {
        expect(typedKeys, hasLength(8));
      });

      test('appears in the text export with typed values winning', () {
        final output = LogExporter.toText(
          logs,
          metadata: full,
          enableRedaction: false,
        );

        for (final MapEntry(:key, :value) in typedKeys.entries) {
          expect(output, contains('$key: $value'));
        }
        expect(output, contains('flavor: qa'));
        expect(output, isNot(contains('stale')));
      });

      test('appears in the markdown export with typed values winning', () {
        final output = LogExporter.toMarkdown(
          logs,
          metadata: full,
          enableRedaction: false,
        );

        for (final MapEntry(:key, :value) in typedKeys.entries) {
          expect(output, contains('> $key: $value'));
        }
        expect(output, contains('> flavor: qa'));
        expect(output, isNot(contains('stale')));
      });

      test('lists typed fields before extra entries in the text export', () {
        final output = LogExporter.toText(
          logs,
          metadata: full,
          enableRedaction: false,
        );

        expect(
          output.indexOf('locale: en_US'),
          lessThan(output.indexOf('flavor: qa')),
        );
      });

      test('toMap keeps extra keys first and typed values winning', () {
        expect(full.toMap().keys.take(2), ['flavor', 'appVersion']);
        expect(full.toMap()['appVersion'], '1.2.3');
      });
    });
  });
}
