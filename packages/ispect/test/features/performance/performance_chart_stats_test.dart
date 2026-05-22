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

  group('computeDeliveredFpsFromVsyncs', () {
    test('returns null when there are fewer than two timestamps', () {
      expect(computeDeliveredFpsFromVsyncs(const [], 60), isNull);
      expect(computeDeliveredFpsFromVsyncs([us(0)], 60), isNull);
    });

    test('reports the expected rate when vsyncs are evenly spaced', () {
      final vsyncs = [for (var i = 0; i < 60; i++) us(i * 16.67)];

      final fps = computeDeliveredFpsFromVsyncs(vsyncs, 60);

      expect(fps, isNotNull);
      expect(fps, closeTo(60, 0.5));
    });

    test('clamps to the refresh rate when math nudges above it', () {
      // 5 frames over 60ms = 4 intervals × 15ms ⇒ ~66.7 FPS — physically
      // impossible on a 60Hz display.
      final vsyncs = [for (var i = 0; i < 5; i++) us(i * 15)];

      final fps = computeDeliveredFpsFromVsyncs(vsyncs, 60);

      expect(fps, 60);
    });

    test('ignores samples older than the 1-second window', () {
      // Three "old" frames 5 seconds before the recent burst, plus a tight
      // recent burst at 60 FPS — only the recent ones should count.
      final vsyncs = <int>[
        us(0),
        us(100),
        us(200),
        for (var i = 0; i < 30; i++) us(5000000 + i * 16.67),
      ];

      final fps = computeDeliveredFpsFromVsyncs(vsyncs, 60);

      expect(fps, isNotNull);
      expect(fps, closeTo(60, 1));
    });

    test('returns null when only a single sample lands in the window', () {
      // One recent frame far away from older ones — count in window = 1.
      final vsyncs = [us(0), us(10000000)];

      expect(computeDeliveredFpsFromVsyncs(vsyncs, 60), isNull);
    });

    test('honors a 120Hz refresh ceiling for tight bursts', () {
      final vsyncs = [for (var i = 0; i < 60; i++) us(i * 8.33)];

      final fps = computeDeliveredFpsFromVsyncs(vsyncs, 120);

      expect(fps, isNotNull);
      expect(fps, closeTo(120, 1));
    });

    test('returns null when the window collapses to zero span', () {
      // All vsync timestamps identical — engine clock didn't advance.
      final vsyncs = [for (var i = 0; i < 5; i++) us(100)];

      expect(computeDeliveredFpsFromVsyncs(vsyncs, 60), isNull);
    });
  });
}
