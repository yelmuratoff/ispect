import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/performance/src/stats.dart';

void main() {
  Duration ms(num value) => Duration(microseconds: (value * 1000).round());
  int us(num millis) => (millis * 1000).round();

  group('PerformanceChartStats.fromMicroseconds', () {
    test('returns zeros when the sample window is empty', () {
      final stats = PerformanceChartStats.fromMicroseconds(const [], us(16));

      expect(stats.avg, Duration.zero);
      expect(stats.p90, Duration.zero);
      expect(stats.p99, Duration.zero);
      expect(stats.jankCount, 0);
    });

    test('counts samples strictly greater than the target as jank', () {
      final samples = [us(8), us(16), us(17), us(50)];

      final stats = PerformanceChartStats.fromMicroseconds(samples, us(16));

      expect(
        stats.jankCount,
        2,
        reason: 'frames at exactly the target are not jank',
      );
    });

    test('computes a stable average across the window', () {
      final samples = [us(2), us(4), us(6), us(8)];

      final stats = PerformanceChartStats.fromMicroseconds(samples, us(16));

      expect(stats.avg, ms(5));
    });

    test('reports the nearest-rank p90 for a small window', () {
      final samples = [for (var i = 1; i <= 10; i++) us(i)];

      final stats = PerformanceChartStats.fromMicroseconds(samples, us(16));

      expect(stats.p90, ms(9));
    });

    test('reports the nearest-rank p99 for a small window', () {
      final samples = [for (var i = 1; i <= 10; i++) us(i)];

      final stats = PerformanceChartStats.fromMicroseconds(samples, us(16));

      expect(stats.p99, ms(10));
    });

    test('p99 collapses to the worst frame in a 2-sample window', () {
      final stats = PerformanceChartStats.fromMicroseconds(
        [us(4), us(40)],
        us(16),
      );

      expect(stats.p99, ms(40));
      expect(stats.p90, ms(40));
    });

    test('does not mutate the input list', () {
      final samples = [us(40), us(4), us(10)];

      PerformanceChartStats.fromMicroseconds(samples, us(16));

      expect(samples, [us(40), us(4), us(10)]);
    });

    test('counts every jank sample even when none are below target', () {
      final samples = [us(20), us(30), us(40)];

      final stats = PerformanceChartStats.fromMicroseconds(samples, us(16));

      expect(stats.jankCount, 3);
      expect(stats.p99, ms(40));
    });

    test('handles a single-sample window', () {
      final stats =
          PerformanceChartStats.fromMicroseconds([us(5)], us(16));

      expect(stats.avg, ms(5));
      expect(stats.p90, ms(5));
      expect(stats.p99, ms(5));
      expect(stats.jankCount, 0);
    });
  });

  group('computeSmoothFps', () {
    test('returns null when there are no samples', () {
      expect(computeSmoothFps(const [], 60), isNull);
    });

    test('reports the refresh rate when totalSpan matches one vsync', () {
      // 120Hz vsync ≈ 8333us; smooth steady state should read at the cap.
      final totalSpans = [for (var i = 0; i < 10; i++) us(8.333)];

      expect(computeSmoothFps(totalSpans, 120), closeTo(120, 0.1));
    });

    test('drops below the refresh rate when avg totalSpan grows', () {
      // Half-and-half mix on 120Hz: five frames at vsync, five at 2× vsync.
      // avg = (5*8.333 + 5*16.666) / 10 = 12.5ms → 80 FPS.
      final totalSpans = [
        for (var i = 0; i < 5; i++) us(8.333),
        for (var i = 0; i < 5; i++) us(16.666),
      ];

      expect(computeSmoothFps(totalSpans, 120), closeTo(80, 0.5));
    });

    test('a single 30 ms hitch is visible in a 10-frame window on 120Hz', () {
      // Previous formula stayed pinned at 120; the new one drops it.
      final totalSpans = [
        for (var i = 0; i < 9; i++) us(8.333),
        us(30),
      ];

      final fps = computeSmoothFps(totalSpans, 120);

      expect(fps, lessThan(120));
      expect(fps, closeTo(95.2, 0.5));
    });

    test('honors a 120Hz refresh ceiling on faster-than-vsync work', () {
      // Engine renders faster than vsync; we still cap at the display rate.
      final totalSpans = [for (var i = 0; i < 5; i++) us(2)];

      expect(computeSmoothFps(totalSpans, 120), 120);
    });

    test('returns refreshRate when total is zero', () {
      expect(computeSmoothFps([us(0)], 60), 60);
    });

    test('uses only the trailing window when more samples are present', () {
      // 20 frames provided, window is 10. The first ten (slow) are ignored,
      // the last ten (fast) drive the reading.
      final totalSpans = [
        for (var i = 0; i < 10; i++) us(40),
        for (var i = 0; i < 10; i++) us(8.333),
      ];

      expect(computeSmoothFps(totalSpans, 120), closeTo(120, 0.5));
    });
  });

  group('missedVsyncs', () {
    test('returns 0 when totalSpan fits the budget', () {
      expect(missedVsyncs(us(8), us(16)), 0);
      expect(missedVsyncs(us(16), us(16)), 0);
    });

    test('reports at least one drop when totalSpan exceeds the budget', () {
      // 16.7 ms barely-over still counts: the next vsync was missed.
      expect(missedVsyncs(us(16.7), us(16.667)), 1);
    });

    test('scales linearly with how many vsyncs were skipped', () {
      expect(missedVsyncs(us(33.3), us(16.667)), 1);
      expect(missedVsyncs(us(50), us(16.667)), 2);
      expect(missedVsyncs(us(100), us(16.667)), 5);
    });

    test('guards against a zero target', () {
      expect(missedVsyncs(us(50), 0), 0);
    });
  });
}
