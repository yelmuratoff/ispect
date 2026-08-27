import 'package:ispect_tool/src/core/exceptions.dart';
import 'package:ispect_tool/src/core/next_version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

Version v(String value) => Version.parse(value);

void main() {
  group('nextPrerelease', () {
    test('increments a trailing numeric identifier', () {
      expect(nextPrerelease(v('7.0.0-dev.1')), v('7.0.0-dev.2'));
      expect(nextPrerelease(v('7.0.0-dev.9')), v('7.0.0-dev.10'));
    });

    test('appends a numeric identifier when the label carries no counter', () {
      expect(nextPrerelease(v('7.0.0-rc')), v('7.0.0-rc.1'));
    });

    test('appends rather than renumbering a counter glued to the label', () {
      expect(nextPrerelease(v('7.0.0-dev9')), v('7.0.0-dev9.1'));
      expect(nextPrerelease(v('7.0.0-dev11')), v('7.0.0-dev11.1'));
      expect(nextPrerelease(v('7.0.0-dev01')), v('7.0.0-dev01.1'));
    });

    test('always returns a version Pub orders above its input', () {
      const series = [
        '7.0.0-dev.1',
        '7.0.0-dev.9',
        '7.0.0-rc',
        '7.0.0-dev9',
        '7.0.0-dev11',
        '7.0.0-dev01',
      ];
      for (final value in series) {
        final current = v(value);
        expect(nextPrerelease(current).compareTo(current), greaterThan(0),
            reason: '$value must rise');
      }
    });

    test('rejects a stable version', () {
      expect(
        () => nextPrerelease(v('7.0.0')),
        throwsA(isA<VersionRegressionException>()),
      );
    });
  });

  group('nextVersion', () {
    test('advances the prerelease counter for a patch bump', () {
      expect(nextVersion(v('7.0.0-dev.11'), BumpKind.patch), v('7.0.0-dev.12'));
    });

    test('increments the patch number of a stable version', () {
      expect(nextVersion(v('7.0.0'), BumpKind.patch), v('7.0.1'));
    });

    test('leaves the prerelease behind on a minor or major bump', () {
      expect(nextVersion(v('7.0.0-dev.11'), BumpKind.minor), v('7.1.0'));
      expect(nextVersion(v('7.0.0-dev.11'), BumpKind.major), v('8.0.0'));
    });
  });

  group('nextDevVersion', () {
    test('advances an existing prerelease', () {
      expect(nextDevVersion(v('7.0.0-dev.11')), v('7.0.0-dev.12'));
    });

    test('opens the series on the next patch, never below the release', () {
      expect(nextDevVersion(v('7.1.0')), v('7.1.1-dev.1'));
      expect(nextDevVersion(v('7.1.0')).compareTo(v('7.1.0')), greaterThan(0));
    });
  });

  group('the published 7.0.0-dev8..dev11 series, glued counters', () {
    test('sorts as text, so dev11 lands below dev8', () {
      expect(v('7.0.0-dev11').compareTo(v('7.0.0-dev8')), lessThan(0));
      expect(v('7.0.0-dev10').compareTo(v('7.0.0-dev9')), lessThan(0));
    });

    test('cannot be rescued by switching to the dot form', () {
      expect(v('7.0.0-dev.11').compareTo(v('7.0.0-dev8')), lessThan(0));
    });

    test('is escaped by appending a counter or leaving the label', () {
      expect(v('7.0.0-dev9.1').compareTo(v('7.0.0-dev9')), greaterThan(0));
      expect(v('7.0.0-rc.1').compareTo(v('7.0.0-dev9')), greaterThan(0));
    });

    test('peaks at dev9, the version Pub ranks highest', () {
      final published = [
        '7.0.0-dev8',
        '7.0.0-dev9',
        '7.0.0-dev10',
        '7.0.0-dev11',
      ].map(v);
      expect(peakInLine(v('7.0.0-dev11.1'), published), v('7.0.0-dev9'));
    });
  });

  group('peakInLine', () {
    final published = ['6.1.6', '6.1.7', '7.0.0-dev9', '7.0.0-dev11', '7.1.0']
        .map(v)
        .toList();

    test('judges a backport against its own line', () {
      expect(peakInLine(v('6.1.8'), published), v('6.1.7'));
      expect(peakInLine(v('7.0.1'), published), v('7.0.0-dev9'));
      expect(peakInLine(v('7.1.1'), published), v('7.1.0'));
    });

    test('reports no peak for a line with nothing published', () {
      expect(peakInLine(v('8.0.0-dev.1'), published), isNull);
    });
  });

  group('hasGluedCounter', () {
    test('flags a counter glued to its label', () {
      expect(hasGluedCounter(v('7.0.0-dev11')), isTrue);
      expect(hasGluedCounter(v('7.0.0-dev01')), isTrue);
    });

    test('accepts the dot form and stable versions', () {
      expect(hasGluedCounter(v('7.0.0-dev.11')), isFalse);
      expect(hasGluedCounter(v('7.0.0-rc.1')), isFalse);
      expect(hasGluedCounter(v('7.0.0')), isFalse);
    });
  });

  group('releaseLine', () {
    test('is the core major.minor, prerelease included', () {
      expect(releaseLine(v('7.0.0-dev11')), '7.0');
      expect(releaseLine(v('7.10.3')), '7.10');
    });
  });

  group('assertRises', () {
    test('rejects an equal or lower version', () {
      expect(
        () => assertRises(v('7.0.0-dev.2'), v('7.0.0-dev.11')),
        throwsA(isA<VersionRegressionException>()),
      );
      expect(
        () => assertRises(v('7.0.0'), v('7.0.0')),
        throwsA(isA<VersionRegressionException>()),
      );
    });
  });
}
