import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/performance/src/sampler.dart';

const _targetUs = 16667;
const _smoothUs = 16000;
const _jankUs = 40000;
const _warm = Duration(milliseconds: 800);

void main() {
  late PerformanceSessionSampler sampler;

  setUp(() => sampler = PerformanceSessionSampler());

  int record(
    List<int> spans, {
    required Duration now,
    bool notifyBursts = true,
    int burstWindow = 3,
    Duration burstCooldown = const Duration(seconds: 1),
  }) => sampler.recordFrameSpans(
    spans,
    targetUs: _targetUs,
    now: now,
    notifyBursts: notifyBursts,
    burstWindow: burstWindow,
    burstCooldown: burstCooldown,
  );

  group('frame spans', () {
    test('ignores dropped frames during warmup', () {
      record([_jankUs], now: Duration.zero);

      expect(sampler.droppedFramesTotal, 0);
      expect(sampler.lastFramePerceptibleDrops, 2);
    });

    test('counts perceptible drops once warmed up', () {
      record([_smoothUs], now: Duration.zero);
      record([_jankUs, _jankUs], now: _warm);

      expect(sampler.droppedFramesTotal, 4);
    });

    test('reports the drops of the last frame in a batch', () {
      record([_jankUs, _smoothUs], now: Duration.zero);

      expect(sampler.lastFramePerceptibleDrops, 0);
    });

    test('fires a burst after consecutive janky frames', () {
      record([_smoothUs], now: Duration.zero);

      expect(record([_jankUs, _jankUs], now: _warm), 0);
      expect(record([_jankUs], now: _warm), 1);
    });

    test('a smooth frame restarts the burst window', () {
      record([_smoothUs], now: Duration.zero);

      expect(record([_jankUs, _jankUs, _smoothUs, _jankUs], now: _warm), 0);
    });

    test('throttles bursts by the cooldown', () {
      record([_smoothUs], now: Duration.zero);
      expect(record([_jankUs, _jankUs, _jankUs], now: _warm), 1);

      expect(
        record([_jankUs], now: _warm + const Duration(milliseconds: 500)),
        0,
      );
      expect(record([_jankUs], now: _warm + const Duration(seconds: 1)), 1);
    });

    test('fires no burst when nobody listens', () {
      record([_smoothUs], now: Duration.zero);

      expect(
        record([_jankUs, _jankUs, _jankUs], now: _warm, notifyBursts: false),
        0,
      );
    });
  });

  group('fps', () {
    test('keeps the session minimum only after warmup', () {
      record([_smoothUs], now: Duration.zero);
      sampler.recordFps(20, now: const Duration(milliseconds: 100));

      expect(sampler.allTimeMinFps, isNull);

      sampler
        ..recordFps(50, now: _warm)
        ..recordFps(55, now: _warm);

      expect(sampler.allTimeMinFps, 50);
    });
  });

  group('jank log slot', () {
    test('grants one slot per cooldown window', () {
      const cooldown = Duration(seconds: 1);

      expect(
        sampler.claimJankLogSlot(now: Duration.zero, cooldown: cooldown),
        isTrue,
      );
      expect(
        sampler.claimJankLogSlot(
          now: const Duration(milliseconds: 999),
          cooldown: cooldown,
        ),
        isFalse,
      );
      expect(
        sampler.claimJankLogSlot(now: cooldown, cooldown: cooldown),
        isTrue,
      );
    });
  });

  group('memory', () {
    void poll(int rss, Duration now) =>
        sampler.pollMemory(now: now, readRssBytes: () => rss);

    test('reads at most once per second', () {
      var reads = 0;
      int read() {
        reads++;
        return 100;
      }

      sampler
        ..pollMemory(now: Duration.zero, readRssBytes: read)
        ..pollMemory(now: const Duration(milliseconds: 500), readRssBytes: read)
        ..pollMemory(now: const Duration(seconds: 1), readRssBytes: read);

      expect(reads, 2);
    });

    test('smooths the displayed value and tracks its peak', () {
      poll(100, Duration.zero);
      poll(200, const Duration(seconds: 1));

      expect(sampler.smoothedRssBytes, 130);
      expect(sampler.peakRssBytes, 130);

      poll(100, const Duration(seconds: 2));

      expect(sampler.smoothedRssBytes, 121);
      expect(sampler.peakRssBytes, 130);
    });

    test('locks the baseline to the median after the settle window', () {
      record([_smoothUs], now: Duration.zero);
      poll(100, _warm);
      poll(300, _warm + const Duration(seconds: 1));

      expect(sampler.baselineRssBytes, isNull);

      poll(200, _warm + const Duration(seconds: 5));

      expect(sampler.baselineRssBytes, 200);
    });

    test('reset snaps the baseline and peak to the smoothed reading', () {
      poll(100, Duration.zero);
      poll(200, const Duration(seconds: 1));

      sampler.reset();

      expect(sampler.baselineRssBytes, 130);
      expect(sampler.peakRssBytes, 130);
    });

    test('collects a baseline after a reset that preceded any reading', () {
      record([_smoothUs], now: Duration.zero);
      sampler.reset();

      poll(100, _warm);
      poll(100, _warm + const Duration(seconds: 5));

      expect(sampler.baselineRssBytes, 100);
    });

    test('reset clears the session counters', () {
      record([_smoothUs], now: Duration.zero);
      record([_jankUs], now: _warm);
      sampler
        ..recordFps(40, now: _warm)
        ..reset();

      expect(sampler.droppedFramesTotal, 0);
      expect(sampler.lastFramePerceptibleDrops, 0);
      expect(sampler.allTimeMinFps, isNull);
    });
  });
}
