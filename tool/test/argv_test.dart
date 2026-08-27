import 'package:ispect_tool/src/cli/argv.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeOptionValues', () {
    test('splits an option that carries its value with an equals sign', () {
      expect(
        normalizeOptionValues(['--bump=patch']),
        ['--bump', 'patch'],
      );
    });

    test('leaves a separated option untouched', () {
      expect(
        normalizeOptionValues(['--bump', 'patch']),
        ['--bump', 'patch'],
      );
    });

    test('leaves flags and positionals untouched', () {
      expect(
        normalizeOptionValues(['release-prep', 'patch', '--dry-run']),
        ['release-prep', 'patch', '--dry-run'],
      );
    });

    test('splits only on the first equals sign', () {
      expect(
        normalizeOptionValues(['--package=a=b']),
        ['--package', 'a=b'],
      );
    });

    test('keeps an empty value rather than dropping the option', () {
      expect(
        normalizeOptionValues(['--package=']),
        ['--package', ''],
      );
    });

    test('does not touch a short option', () {
      expect(normalizeOptionValues(['-v=1']), ['-v=1']);
    });

    test('does not treat a bare -- as an option with a value', () {
      expect(normalizeOptionValues(['--=x']), ['--=x']);
    });

    test('passes everything after a bare -- through untouched', () {
      expect(
        normalizeOptionValues(['--bump=patch', '--', '--bump=minor', 'a=b']),
        ['--bump', 'patch', '--', '--bump=minor', 'a=b'],
      );
    });

    test('returns an empty list unchanged', () {
      expect(normalizeOptionValues([]), isEmpty);
    });
  });
}
