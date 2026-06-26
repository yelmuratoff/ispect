import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('ISpectRedaction global kill-switch', () {
    tearDown(() => ISpectRedaction.enabled = true);

    test('defaults to enabled so redaction is on out of the box', () {
      expect(ISpectRedaction.enabled, isTrue);
    });

    group('when disabled, RedactionService passes data through unchanged', () {
      setUp(() => ISpectRedaction.enabled = false);

      test('redact returns the payload verbatim', () {
        final service = RedactionService();
        final input = <String, Object?>{'password': 'p@ss', 'keep': 'v'};
        expect(service.redact(input), input);
      });

      test('redactHeaders returns headers verbatim', () {
        final service = RedactionService();
        final headers = <String, Object?>{'authorization': 'Bearer abc'};
        expect(service.redactHeaders(headers), headers);
      });

      test('redactUrl keeps sensitive query params and credentials', () {
        final service = RedactionService();
        const url = 'https://user:secret@api.test/path?token=abc123';
        expect(service.redactUrl(url), url);
      });

      test('redactUrlsInText leaves embedded URLs untouched', () {
        final service = RedactionService();
        const text = 'failed: https://api.test/path?token=abc123';
        expect(service.redactUrlsInText(text), text);
      });

      test('redactWithStats reports no redactions', () {
        final service = RedactionService();
        final result = service.redactWithStats({'password': 'p@ss'});
        expect(result.data, {'password': 'p@ss'});
        expect(result.stats.total, 0);
        expect(result.stats.hasRedactions, isFalse);
      });

      test('redactHeadersWithStats reports no redactions', () {
        final service = RedactionService();
        final result =
            service.redactHeadersWithStats({'authorization': 'Bearer abc'});
        expect(result.headers, {'authorization': 'Bearer abc'});
        expect(result.stats.total, 0);
      });

      test('static redactByKeys returns data verbatim', () {
        final out = RedactionService.redactByKeys(
          {'password': 'p@ss', 'keep': 'v'},
          {'password'},
        );
        expect(out, {'password': 'p@ss', 'keep': 'v'});
      });

      test('static redactExportString keeps tokens', () {
        const value = 'Authorization: Bearer super-secret-token';
        expect(
          RedactionService.redactExportString(value, defaultSensitiveKeys),
          value,
        );
      });

      test('static redactTarget keeps query params and credentials', () {
        const target = 'https://user:pw@api.test/p?token=abc123';
        expect(
          RedactionService.redactTarget(target, defaultSensitiveKeys),
          target,
        );
      });
    });

    group('when enabled (default), redaction still applies', () {
      test('redact masks sensitive keys', () {
        final out = RedactionService().redact(
          {'password': 'p@ss', 'keep': 'v'},
        )! as Map<String, Object?>;
        expect(out['password'], defaultPlaceholder);
        expect(out['keep'], 'v');
      });

      test('redactUrl masks sensitive query params', () {
        final out =
            RedactionService().redactUrl('https://api.test/p?token=abc123');
        expect(out, isNot(contains('abc123')));
      });

      test('static redactByKeys masks matched keys', () {
        final out = RedactionService.redactByKeys(
          {'password': 'p@ss'},
          {'password'},
        )! as Map<String, Object?>;
        expect(out['password'], defaultPlaceholder);
      });

      test('static redactExportString masks bearer tokens', () {
        final out = RedactionService.redactExportString(
          'Authorization: Bearer super-secret-token',
          defaultSensitiveKeys,
        );
        expect(out, isNot(contains('super-secret-token')));
      });
    });

    test('re-enabling after a disable restores masking', () {
      final service = RedactionService();
      ISpectRedaction.enabled = false;
      expect(service.redact({'password': 'p@ss'}), {'password': 'p@ss'});

      ISpectRedaction.enabled = true;
      final out = service.redact({'password': 'p@ss'})! as Map<String, Object?>;
      expect(out['password'], defaultPlaceholder);
    });
  });
}
