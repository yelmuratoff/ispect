import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/performance/src/stats.dart';

void main() {
  Duration ms(num value) =>
      Duration(microseconds: (value * 1000).round());

  /// Microseconds since some monotonic epoch — values don't matter, only
  /// their deltas do.
  int us(num millis) => (millis * 1000).round();

  group('PerformanceChartStats.from', () {
    test('returns zeros when the sample window is empty', () {
      final stats = PerformanceChartStats.from(const [], ms(16));

      expect(stats.avg, Duration.zero);
      expect(stats.p90, Duration.zero);
      expect(stats.p99, Duration.zero);
      expect(stats.jankCount, 0);
    });

    test('counts samples strictly greater than the target as jank', () {
      final samples = [ms(8), ms(16), ms(17), ms(50)];

      final stats = PerformanceChartStats.from(samples, ms(16));

      expect(
        stats.jankCount,
        2,
        reason: 'frames at exactly the target are not jank',
      );
    });

    test('computes a stable average across the window', () {
      final samples = [ms(2), ms(4), ms(6), ms(8)];

      final stats = PerformanceChartStats.from(samples, ms(16));

      expect(stats.avg, ms(5));
    });

    test('reports the nearest-rank p90 for a small window', () {
      final samples = [for (var i = 1; i <= 10; i++) ms(i)];

      final stats = PerformanceChartStats.from(samples, ms(16));

      // ceil(10 * 0.90) − 1 = 8 → sorted[8] == ms(9).
      expect(stats.p90, ms(9));
    });

    test('reports the nearest-rank p99 for a small window', () {
      final samples = [for (var i = 1; i <= 10; i++) ms(i)];

      final stats = PerformanceChartStats.from(samples, ms(16));

      // ceil(10 * 0.99) − 1 = 9 → sorted[9] == ms(10).
      expect(stats.p99, ms(10));
    });

    test('p99 collapses to the worst frame in a 2-sample window', () {
      final stats = PerformanceChartStats.from([ms(4), ms(40)], ms(16));

      expect(stats.p99, ms(40));
      expect(stats.p90, ms(40));
    });

    test('does not mutate the input list', () {
      final samples = [ms(40), ms(4), ms(10)];

      PerformanceChartStats.from(samples, ms(16));

      expect(samples, [ms(40), ms(4), ms(10)]);
    });

    test('counts every jank sample even when none are below target', () {
      final samples = [ms(20), ms(30), ms(40)];

      final stats = PerformanceChartStats.from(samples, ms(16));

      expect(stats.jankCount, 3);
      expect(stats.p99, ms(40));
    });

    test('handles a single-sample window', () {
      final stats = PerformanceChartStats.from([ms(5)], ms(16));

      expect(stats.avg, ms(5));
      expect(stats.p90, ms(5));
      expect(stats.p99, ms(5));
      expect(stats.jankCount, 0);
    });
  });

  group('computeEffectiveFps', () {
    test('returns null when there are no samples', () {
      expect(computeEffectiveFps(const [], const [], 60), isNull);
    });

    test('returns null when build/raster lists disagree on length', () {
      expect(computeEffectiveFps([us(1)], const [], 60), isNull);
    });

    test('reports the refresh rate when both threads fit the frame budget',
        () {
      final builds = [for (var i = 0; i < 10; i++) us(1)];
      final rasters = [for (var i = 0; i < 10; i++) us(1)];

      final fps = computeEffectiveFps(builds, rasters, 120);

      expect(fps, 120);
    });

    test('drops below the refresh rate when one thread is the bottleneck',
        () {
      // avg build 20ms ⇒ engine cannot sustain more than 50 FPS even though
      // raster is fast.
      final builds = [for (var i = 0; i < 5; i++) us(20)];
      final rasters = [for (var i = 0; i < 5; i++) us(2)];

      final fps = computeEffectiveFps(builds, rasters, 60);

      expect(fps, closeTo(50, 0.1));
    });

    test('uses raster as the bottleneck when raster is slower than build',
        () {
      final builds = [for (var i = 0; i < 5; i++) us(2)];
      final rasters = [for (var i = 0; i < 5; i++) us(25)];

      final fps = computeEffectiveFps(builds, rasters, 60);

      expect(fps, closeTo(40, 0.1));
    });

    test('returns refreshRate when bottleneck duration is zero', () {
      final fps = computeEffectiveFps([us(0)], [us(0)], 60);

      expect(fps, 60);
    });

    test('honors a 120Hz refresh ceiling', () {
      final builds = [for (var i = 0; i < 5; i++) us(0.5)];
      final rasters = [for (var i = 0; i < 5; i++) us(0.5)];

      final fps = computeEffectiveFps(builds, rasters, 120);

      expect(fps, 120);
    });
  });
}
