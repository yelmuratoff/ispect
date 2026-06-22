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
      final stats = PerformanceChartStats.fromMicroseconds([us(5)], us(16));

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
    const target120Hz = 8333;

    test('returns 0 when totalSpan fits the budget', () {
      expect(missedVsyncs(us(8), us(16)), 0);
      expect(missedVsyncs(us(16), us(16)), 0);
    });

    test('counts any over-target frame as at least one missed vsync', () {
      // A 9 ms frame on 120Hz held the previous buffer for 16.67 ms — one
      // vsync was demonstrably skipped. The raw counter does not filter for
      // perceptibility; that is what `perceptibleDrops` is for.
      expect(missedVsyncs(9000, target120Hz), 1);
      expect(missedVsyncs(12000, target120Hz), 1);
      expect(missedVsyncs(16000, target120Hz), 1);
    });

    test('uses the ceiling formula across vsync boundaries', () {
      // 17 ms on 120Hz: previous buffer held until vsync 3 = 25 ms total =
      // 2 vsyncs missed.
      expect(missedVsyncs(17000, target120Hz), 2);
    });

    test('scales linearly with how many vsync windows were consumed', () {
      // Clean 10 ms target keeps the arithmetic exact and the intent legible.
      const cleanTarget = 10000;
      expect(missedVsyncs(20000, cleanTarget), 1);
      expect(missedVsyncs(30000, cleanTarget), 2);
      expect(missedVsyncs(50000, cleanTarget), 4);
      expect(missedVsyncs(100000, cleanTarget), 9);
    });

    test('guards against a zero target', () {
      expect(missedVsyncs(us(50), 0), 0);
    });
  });

  group('perceptibleDrops', () {
    const target120Hz = 8333;
    const target60Hz = 16667;

    test('returns 0 for an on-target frame', () {
      expect(perceptibleDrops(8000, target120Hz), 0);
      expect(perceptibleDrops(target120Hz, target120Hz), 0);
    });

    test('does not count single-vsync skips on a 120Hz panel', () {
      // Scroll-noise frames (9–17 ms) skip one 120Hz vsync but the resulting
      // display lag is below the perception threshold. The drop counter must
      // stay quiet here — that is the entire point of the metric.
      expect(perceptibleDrops(9000, target120Hz), 0);
      expect(perceptibleDrops(12000, target120Hz), 0);
      expect(perceptibleDrops(17000, target120Hz), 0);
      expect(perceptibleDrops(24000, target120Hz), 0);
    });

    test('counts a 120Hz frame as a drop once display gap reaches 60Hz', () {
      // ~33 ms on 120Hz: three vsyncs skipped, previous buffer held 25 ms
      // beyond schedule — one 60Hz frame of visible stutter.
      expect(perceptibleDrops(33000, target120Hz), 1);
    });

    test('scales with how many 60Hz frames worth of stutter accumulated', () {
      // 50 ms on 120Hz: excess display ≈ 50 ms → ≈ 3 × 60Hz frames of
      // stutter, but integer arithmetic against the 16667-µs threshold
      // resolves to 2 (49998 / 16667 = 2). The hitch metric is a heuristic;
      // the off-by-one near boundaries is acceptable. 100 ms → 5 drops.
      expect(perceptibleDrops(50000, target120Hz), 2);
      expect(perceptibleDrops(100000, target120Hz), 5);
    });

    test('counts the first missed vsync on a 60Hz panel', () {
      // On 60Hz the target itself is the perception threshold, so any
      // over-target frame already produces ≥ 16.67 ms of display lag.
      expect(perceptibleDrops(20000, target60Hz), 1);
      expect(perceptibleDrops(33333, target60Hz), 1);
      expect(perceptibleDrops(50000, target60Hz), 2);
    });

    test('guards against a zero target', () {
      expect(perceptibleDrops(us(50), 0), 0);
    });
  });
}
