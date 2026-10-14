import 'package:ispect/src/features/performance/src/stats.dart';
import 'package:meta/meta.dart';

/// Discards startup spikes (JIT, asset decode, shader cache) from session
/// min FPS and drop counter.
const Duration _kWarmupDuration = Duration(milliseconds: 800);

/// RSS rarely changes within one frame; sampling at 1 Hz keeps the readout
/// useful without burning syscalls every tick.
const Duration _kMemoryPollInterval = Duration(seconds: 1);

/// How long after warmup to collect baseline samples before locking in their
/// median. Lets the app navigate past the lightweight splash/first screen so
/// the reference point reflects "normal" steady-state usage, not boot.
const Duration _kMemoryBaselineSettleWindow = Duration(seconds: 5);

/// EWMA smoothing factor for the displayed RSS value - α≈0.3 gives roughly
/// a 3-sample effective window, enough to swallow GC/allocator jiggle
/// without lagging real growth by more than ~3 seconds.
const double _kMemoryEwmaAlpha = 0.3;

@internal
final class PerformanceSessionSampler {
  Duration? _warmupStartedAt;
  double _allTimeMinFps = double.infinity;
  int _droppedFramesTotal = 0;
  int _lastFramePerceptibleDrops = 0;
  int _consecutiveJankCount = 0;
  Duration? _lastJankBurstAt;
  Duration? _lastJankLogAt;
  Duration? _lastMemoryPollAt;
  int? _currentRssBytes;
  int? _smoothedRssBytes;
  int? _peakRssBytes;
  int? _baselineRssBytes;
  List<int> _baselineSamples = <int>[];

  double? get allTimeMinFps =>
      _allTimeMinFps == double.infinity ? null : _allTimeMinFps;
  int get droppedFramesTotal => _droppedFramesTotal;
  int get lastFramePerceptibleDrops => _lastFramePerceptibleDrops;
  int? get smoothedRssBytes => _smoothedRssBytes;
  int? get peakRssBytes => _peakRssBytes;
  int? get baselineRssBytes => _baselineRssBytes;

  bool isWarmedUp(Duration now) {
    final startedAt = _warmupStartedAt;
    return startedAt != null && now - startedAt >= _kWarmupDuration;
  }

  int recordFrameSpans(
    Iterable<int> totalSpansUs, {
    required int targetUs,
    required Duration now,
    required bool notifyBursts,
    required int burstWindow,
    required Duration burstCooldown,
  }) {
    _warmupStartedAt ??= now;
    final warmedUp = isWarmedUp(now);
    var bursts = 0;
    var lastPerceptible = 0;
    for (final totalUs in totalSpansUs) {
      final missed = missedVsyncs(totalUs, targetUs);
      final perceptible = perceptibleDrops(totalUs, targetUs);
      lastPerceptible = perceptible;
      if (missed == 0) {
        _consecutiveJankCount = 0;
        continue;
      }
      if (warmedUp) _droppedFramesTotal += perceptible;
      _consecutiveJankCount++;
      final lastBurstAt = _lastJankBurstAt;
      if (warmedUp &&
          notifyBursts &&
          _consecutiveJankCount >= burstWindow &&
          (lastBurstAt == null || now - lastBurstAt >= burstCooldown)) {
        _lastJankBurstAt = now;
        bursts++;
      }
    }
    _lastFramePerceptibleDrops = lastPerceptible;
    return bursts;
  }

  void recordFps(double? fps, {required Duration now}) {
    if (isWarmedUp(now) && fps != null && fps > 0 && fps < _allTimeMinFps) {
      _allTimeMinFps = fps;
    }
  }

  bool claimJankLogSlot({required Duration now, required Duration cooldown}) {
    final lastLogAt = _lastJankLogAt;
    if (lastLogAt != null && now - lastLogAt < cooldown) return false;
    _lastJankLogAt = now;
    return true;
  }

  void pollMemory({
    required Duration now,
    required int? Function() readRssBytes,
  }) {
    final lastPollAt = _lastMemoryPollAt;
    if (lastPollAt != null && now - lastPollAt < _kMemoryPollInterval) return;
    _lastMemoryPollAt = now;
    final rss = readRssBytes();
    if (rss == null) return;
    _currentRssBytes = rss;
    // Smooth the *displayed* value with an EWMA so GC/allocator jiggle does
    // not flicker the colour tier. Peak and baseline observe this smoothed
    // signal too - a brief allocation spike that GC immediately collects
    // should not pin peak.
    final previousSmoothed = _smoothedRssBytes;
    final smoothed = previousSmoothed == null
        ? rss
        : (_kMemoryEwmaAlpha * rss + (1 - _kMemoryEwmaAlpha) * previousSmoothed)
              .round();
    _smoothedRssBytes = smoothed;
    // Baseline: collect samples for `_kMemoryBaselineSettleWindow` after
    // warmup, then lock in the median. Median is robust to a single big
    // navigation that lands during the window.
    final startedAt = _warmupStartedAt;
    if (startedAt != null && isWarmedUp(now) && _baselineRssBytes == null) {
      _baselineSamples.add(rss);
      if (now - startedAt >= _kWarmupDuration + _kMemoryBaselineSettleWindow) {
        _baselineRssBytes = _medianInt(_baselineSamples);
        _baselineSamples = <int>[];
      }
    }
    final previousPeak = _peakRssBytes;
    if (previousPeak == null || smoothed > previousPeak) {
      _peakRssBytes = smoothed;
    }
  }

  void reset() {
    _allTimeMinFps = double.infinity;
    _droppedFramesTotal = 0;
    _lastFramePerceptibleDrops = 0;
    _consecutiveJankCount = 0;
    _lastJankBurstAt = null;
    _lastJankLogAt = null;
    // Snap baseline and peak to the last smoothed reading so colouring
    // restarts from "now" without the 5s settle gap.
    final snapped = _smoothedRssBytes ?? _currentRssBytes;
    _peakRssBytes = snapped;
    _baselineRssBytes = snapped;
    _baselineSamples = <int>[];
  }

  static int _medianInt(List<int> samples) {
    final sorted = List<int>.of(samples)..sort();
    final n = sorted.length;
    if (n.isOdd) return sorted[n ~/ 2];
    return ((sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2).round();
  }
}
