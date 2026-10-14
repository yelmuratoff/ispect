import 'dart:typed_data';
import 'dart:ui' show VertexMode, Vertices;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ispect/src/features/performance/src/memory_stats.dart'
    as memory;
import 'package:ispect/src/features/performance/src/overlay_config.dart';
import 'package:ispect/src/features/performance/src/sampler.dart';
import 'package:ispect/src/features/performance/src/stats.dart';
import 'package:ispect/src/ispect.dart';
import 'package:ispectify/ispectify.dart';

/// Fallback when [View.display.refreshRate] is unavailable.
const double _kFallbackRefreshRate = 60;

const double _kBarGap = 1;
const double _kHeaderHeight = 16;
const double _kPauseButtonSize = 18;
const double _kStatsFontSize = 10;
const double _kHeaderFontSize = 9;
const double _kStatsLineHeight = 1.15;
const double _kCapMarkerHeight = 4;
const double _kColumnDividerWidth = 1;
const double _kCompactHeight = 24;
const EdgeInsets _kStatsPadding = EdgeInsets.fromLTRB(4, 2, 4, 0);
const EdgeInsets _kHeaderPadding = EdgeInsets.symmetric(
  horizontal: 6,
  vertical: 1,
);
const EdgeInsets _kCompactPadding = EdgeInsets.symmetric(
  horizontal: 6,
  vertical: 4,
);

const String _kOverlaySemanticsLabel = 'Performance overlay';

const double _kFpsHealthyRatio = 0.95;
const double _kFpsWarningRatio = 0.80;

/// The default overlay is not color-blind safe. Opt in by passing each
/// `colorBlind*` value into the matching overlay parameter - including
/// [colorBlindOverTarget], which the default `overTargetColor` does not pick
/// up automatically.
abstract final class ISpectPerformanceOverlayPalettes {
  static const ui = Colors.teal;
  static const raster = Colors.blue;
  static const total = Colors.purple;

  /// Wong/Okabe palette, distinguishable under deuteranopia, protanopia, and
  /// tritanopia.
  static const colorBlindUi = Color(0xFF009E73);
  static const colorBlindRaster = Color(0xFFE69F00);
  static const colorBlindTotal = Color(0xFFCC79A7);
  static const colorBlindOverTarget = Color(0xFFD55E00);
}

/// Cross-platform performance overlay built on [FrameTiming] - works on web
/// and desktop where Flutter's native [PerformanceOverlay] does not.
///
/// UI build and raster are each checked against the full frame target (not
/// half) because the two threads pipeline across frames. The "8ms + 8ms"
/// split in the Flutter docs is about input-to-display latency, not jank.
///
/// As with Flutter's native overlay, the readings are only meaningful in
/// profile mode - debug-mode asserts and JIT inflate frame work, so numbers
/// there exist to spot trends, not to evaluate release-build performance.
class ISpectPerformanceOverlay extends StatefulWidget {
  const ISpectPerformanceOverlay({
    required this.child,
    super.key,
    this.enabled = true,
    this.alignment = Alignment.topRight,
    this.scale = 1,
    this.width,
    this.height,
    this.sampleSize = 64,
    this.targetFrameTime,
    this.barRangeMax = const Duration(milliseconds: 50),
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.uiColor = Colors.teal,
    this.rasterColor = Colors.blue,
    this.totalColor = Colors.purple,
    this.overTargetColor = const Color(0xFFFF5252),
    this.compact = false,
    this.showP90 = false,
    this.allowFreeze = true,
    this.onFrameTiming,
    this.enableJankLogging = false,
    this.severeJankFactor = 2.0,
    this.jankLogCooldown = const Duration(seconds: 1),
    this.showMemory = true,
    this.memoryWarnRatio = 1.3,
    this.memoryDangerRatio = 2.0,
    this.showAllTimeStats = false,
    this.onJankBurst,
    this.jankBurstWindow = 3,
    this.jankBurstCooldown = const Duration(seconds: 1),
  }) : assert(severeJankFactor >= 1.0, 'severeJankFactor must be >= 1'),
       assert(sampleSize > 0, 'sampleSize must be > 0'),
       assert(jankBurstWindow > 0, 'jankBurstWindow must be > 0'),
       assert(memoryWarnRatio >= 1.0, 'memoryWarnRatio must be >= 1'),
       assert(
         memoryDangerRatio > memoryWarnRatio,
         'memoryDangerRatio must exceed memoryWarnRatio',
       );

  final bool enabled;

  /// Horizontal alignment only takes effect when [width] is finite; with a
  /// `null` width the overlay fills the available width regardless.
  final Alignment alignment;

  final double scale;

  /// `null` fills the available horizontal space.
  final double? width;

  /// `null` picks a default sized for [compact] / [showP90].
  final double? height;

  final int sampleSize;

  /// Total frame budget; applied identically to UI, raster, and total. When
  /// `null`, derived from the active display's refresh rate. All three
  /// metrics share the same target because UI and raster pipeline across
  /// frames - both threads independently get the full per-frame budget.
  final Duration? targetFrameTime;

  /// Bars beyond this are visually capped and marked with a notch.
  final Duration barRangeMax;

  final Color backgroundColor;

  /// Drives text labels, the target line, and the freeze button glyph.
  final Color textColor;

  final Color uiColor;
  final Color rasterColor;
  final Color totalColor;

  /// Applied to bars **and** labels that exceed the per-metric target.
  final Color overTargetColor;

  /// Render a single-line summary instead of three charts.
  final bool compact;

  /// Show p90 alongside p99 in the detailed layout. No effect in [compact].
  final bool showP90;

  /// Show the small freeze button for pausing the chart in place.
  /// A long-press on the same button resets session counters (all-time
  /// min FPS and dropped-frame total).
  final bool allowFreeze;

  /// Fires for every collected [FrameTiming], including while the chart is
  /// frozen so a downstream pipeline does not lose data. The first reported
  /// frame is dropped to filter warm-up noise (JIT compile, asset decode,
  /// shader cache miss), so this callback will not see it either.
  ///
  /// Invoked synchronously from `SchedulerBinding.addTimingsCallback` - keep
  /// the body in microseconds or defer work to a post-frame callback /
  /// isolate. Exceptions are caught and routed through [ISpect.logger] so
  /// they do not poison the engine's timings dispatch.
  final void Function(FrameTiming timing)? onFrameTiming;

  /// Log frames where `max(buildDuration, rasterDuration) > targetFrameTime ×
  /// severeJankFactor` via [ISpect.logger]. Off by default to avoid log spam.
  /// Numbers are misleading in debug mode (JIT, asserts, scheduling delays);
  /// turn it on for profile/release builds.
  final bool enableJankLogging;

  /// `2.0` matches "visible hitch" on 60Hz; below `1.0` would log every
  /// frame above target.
  final double severeJankFactor;

  /// Minimum gap between two consecutive jank log entries. A sustained jank
  /// session (e.g. log viewer rebuilding itself on every new entry) can
  /// otherwise create a feedback loop where each log triggers more frame
  /// work. Defaults to one second.
  final Duration jankLogCooldown;

  /// Show current process RSS in the header and `peak MB` under
  /// [showAllTimeStats]. Falls back to no-op on web where `dart:io` is
  /// unavailable.
  final bool showMemory;

  /// RSS within `[1.0, memoryWarnRatio]` of the post-warmup baseline keeps
  /// the readout neutral; beyond it the colour switches to warn.
  final double memoryWarnRatio;

  /// RSS above `memoryDangerRatio × baseline` is rendered in
  /// [overTargetColor]. Defaults to `2.0` - RSS doubling since the baseline
  /// usually signals a leak or unbounded cache.
  final double memoryDangerRatio;

  /// Append session-wide `min · drop` figures next to the FPS reading.
  final bool showAllTimeStats;

  /// Fires after [jankBurstWindow] consecutive over-target frames, throttled
  /// by [jankBurstCooldown]. Runs on the engine's timings dispatch - keep
  /// the body fast.
  final void Function(double currentFps)? onJankBurst;

  final int jankBurstWindow;

  final Duration jankBurstCooldown;

  final Widget child;

  @override
  State<ISpectPerformanceOverlay> createState() =>
      _ISpectPerformanceOverlayState();
}

class _ISpectPerformanceOverlayState extends State<ISpectPerformanceOverlay> {
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    assert(
      widget.barRangeMax.inMicroseconds > 0,
      'barRangeMax must be greater than zero',
    );
    assert(
      widget.targetFrameTime == null ||
          widget.targetFrameTime!.inMicroseconds > 0,
      'targetFrameTime must be positive when provided',
    );
    assert(
      widget.targetFrameTime == null ||
          widget.targetFrameTime!.inMicroseconds <=
              widget.barRangeMax.inMicroseconds,
      'targetFrameTime must fit within barRangeMax so the target line can '
      'render inside the chart',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final target = widget.targetFrameTime ?? _resolveTargetFromDisplay(context);
    final refreshRate = _resolveRefreshRate(context);
    final resolvedHeight = widget.height ?? _defaultHeight();

    Widget overlay = SizedBox(
      width: widget.width,
      height: resolvedHeight,
      child: _OverlayBody(
        config: PerformanceOverlayConfig(
          sampleSize: widget.sampleSize,
          target: target,
          refreshRate: refreshRate,
          barRangeMax: widget.barRangeMax,
          backgroundColor: widget.backgroundColor,
          textColor: widget.textColor,
          uiColor: widget.uiColor,
          rasterColor: widget.rasterColor,
          totalColor: widget.totalColor,
          overTargetColor: widget.overTargetColor,
          compact: widget.compact,
          showP90: widget.showP90,
          allowFreeze: widget.allowFreeze,
          enableJankLogging: widget.enableJankLogging,
          severeJankFactor: widget.severeJankFactor,
          jankLogCooldown: widget.jankLogCooldown,
          showMemory: widget.showMemory,
          memoryWarnRatio: widget.memoryWarnRatio,
          memoryDangerRatio: widget.memoryDangerRatio,
          showAllTimeStats: widget.showAllTimeStats,
          jankBurstWindow: widget.jankBurstWindow,
          jankBurstCooldown: widget.jankBurstCooldown,
        ),
        paused: _paused,
        onTogglePause: _togglePause,
        onFrameTiming: widget.onFrameTiming,
        onJankBurst: widget.onJankBurst,
      ),
    );
    // Skip the Transform layer in the common (default) case so the engine
    // does not allocate one just to apply an identity matrix.
    if (widget.scale != 1) {
      overlay = Transform.scale(
        alignment: widget.alignment,
        scale: widget.scale,
        child: overlay,
      );
    }

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final alignY = widget.alignment.y;
    final insetPadding = EdgeInsets.only(
      top: alignY < 0 ? viewPadding.top : 0,
      bottom: alignY > 0 ? viewPadding.bottom : 0,
    );

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Align(
            alignment: widget.alignment,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: RepaintBoundary(
                child: ColoredBox(
                  color: widget.backgroundColor,
                  child: Padding(padding: insetPadding, child: overlay),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _togglePause() => setState(() => _paused = !_paused);

  double _defaultHeight() {
    if (widget.compact) return _kCompactHeight;
    final statLines = widget.showP90 ? 4 : 3;
    final textBlock = _kStatsFontSize * _kStatsLineHeight * statLines;
    return _kHeaderHeight + textBlock + 18;
  }

  static Duration _resolveTargetFromDisplay(BuildContext context) =>
      Duration(microseconds: (1e6 / _resolveRefreshRate(context)).round());

  static double _resolveRefreshRate(BuildContext context) {
    final view = View.maybeOf(context);
    final hz = view?.display.refreshRate ?? 0;
    return hz > 0 ? hz : _kFallbackRefreshRate;
  }
}

@immutable
class _OverlaySnapshot {
  const _OverlaySnapshot({
    required this.uiUs,
    required this.rasterUs,
    required this.totalUs,
    required this.uiStats,
    required this.rasterStats,
    required this.totalStats,
    required this.fps,
    required this.lastFramePerceptibleDrops,
    required this.allTimeMinFps,
    required this.droppedFramesTotal,
    required this.rssBytes,
    required this.peakRssBytes,
    required this.baselineRssBytes,
  });

  final List<int> uiUs;
  final List<int> rasterUs;
  final List<int> totalUs;

  final PerformanceChartStats uiStats;
  final PerformanceChartStats rasterStats;
  final PerformanceChartStats totalStats;

  final double? fps;

  /// Surfaces the latest hitch in the header before it ages out of the FPS
  /// window.
  final int lastFramePerceptibleDrops;

  final double? allTimeMinFps;

  final int droppedFramesTotal;

  /// Most recent process RSS in bytes, `null` on web or before the first
  /// memory poll.
  final int? rssBytes;

  /// Session-wide peak RSS in bytes, reset together with the other session
  /// counters via long-press on the freeze button.
  final int? peakRssBytes;

  /// First stable RSS sample captured after warmup; used as the reference
  /// point for growth-tier coloring. Reset alongside [peakRssBytes].
  final int? baselineRssBytes;

  static const _OverlaySnapshot empty = _OverlaySnapshot(
    uiUs: <int>[],
    rasterUs: <int>[],
    totalUs: <int>[],
    uiStats: PerformanceChartStats.zero,
    rasterStats: PerformanceChartStats.zero,
    totalStats: PerformanceChartStats.zero,
    fps: null,
    lastFramePerceptibleDrops: 0,
    allTimeMinFps: null,
    droppedFramesTotal: 0,
    rssBytes: null,
    peakRssBytes: null,
    baselineRssBytes: null,
  );
}

class _OverlayBody extends StatefulWidget {
  const _OverlayBody({
    required this.config,
    required this.paused,
    required this.onTogglePause,
    required this.onFrameTiming,
    required this.onJankBurst,
  });

  final PerformanceOverlayConfig config;
  final bool paused;
  final VoidCallback onTogglePause;
  final void Function(FrameTiming timing)? onFrameTiming;
  final void Function(double currentFps)? onJankBurst;

  @override
  State<_OverlayBody> createState() => _OverlayBodyState();
}

class _OverlayBodyState extends State<_OverlayBody> {
  final ValueNotifier<_OverlaySnapshot> _snapshot =
      ValueNotifier<_OverlaySnapshot>(_OverlaySnapshot.empty);

  final List<int> _uiUs = <int>[];
  final List<int> _rasterUs = <int>[];
  final List<int> _totalUs = <int>[];

  bool _skippedFirstSample = false;
  final Stopwatch _clock = Stopwatch()..start();
  final PerformanceSessionSampler _sampler = PerformanceSessionSampler();

  PerformanceOverlayConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timingsCallback);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_timingsCallback);
    _snapshot.dispose();
    super.dispose();
  }

  void _timingsCallback(List<FrameTiming> frameTimings) {
    if (!mounted) return;

    final newSamples = _skippedFirstSample
        ? frameTimings
        : frameTimings.length > 1
        ? frameTimings.sublist(1)
        : const <FrameTiming>[];
    _skippedFirstSample = true;

    if (newSamples.isEmpty) return;
    final now = _clock.elapsed;
    final config = _config;

    final onTiming = widget.onFrameTiming;
    if (onTiming != null) {
      for (final t in newSamples) {
        try {
          onTiming(t);
        } catch (e, st) {
          ISpect.logger.handle(
            exception: e,
            stackTrace: st,
            message: 'ISpectPerformanceOverlay.onFrameTiming threw',
          );
        }
      }
    }
    if (config.enableJankLogging) {
      _logSevereJank(newSamples, now);
    }
    _reportJankBursts(newSamples, now);

    if (widget.paused) return;

    final targetUs = config.target.inMicroseconds;
    for (final t in newSamples) {
      _uiUs.add(t.buildDuration.inMicroseconds);
      _rasterUs.add(t.rasterDuration.inMicroseconds);
      _totalUs.add(t.totalSpan.inMicroseconds);
    }
    _trimToWindow(_uiUs);
    _trimToWindow(_rasterUs);
    _trimToWindow(_totalUs);

    final fps = computeSmoothFps(_totalUs, config.refreshRate);
    _sampler.recordFps(fps, now: now);

    if (config.showMemory) {
      _sampler.pollMemory(now: now, readRssBytes: memory.readCurrentRssBytes);
    }

    // Painter reads these inside the same frame this callback runs in,
    // before the next engine dispatch can mutate them - defensive copies
    // would just churn the GC.
    _snapshot.value = _OverlaySnapshot(
      uiUs: _uiUs,
      rasterUs: _rasterUs,
      totalUs: _totalUs,
      uiStats: PerformanceChartStats.fromMicroseconds(_uiUs, targetUs),
      rasterStats: PerformanceChartStats.fromMicroseconds(_rasterUs, targetUs),
      totalStats: PerformanceChartStats.fromMicroseconds(_totalUs, targetUs),
      fps: fps,
      lastFramePerceptibleDrops: _sampler.lastFramePerceptibleDrops,
      allTimeMinFps: _sampler.allTimeMinFps,
      droppedFramesTotal: _sampler.droppedFramesTotal,
      rssBytes: _sampler.smoothedRssBytes,
      peakRssBytes: _sampler.peakRssBytes,
      baselineRssBytes: _sampler.baselineRssBytes,
    );
  }

  void _trimToWindow(List<int> buffer) {
    final overflow = buffer.length - _config.sampleSize;
    if (overflow > 0) buffer.removeRange(0, overflow);
  }

  void _reportJankBursts(List<FrameTiming> samples, Duration now) {
    final config = _config;
    final onBurst = widget.onJankBurst;
    final bursts = _sampler.recordFrameSpans(
      samples.map((t) => t.totalSpan.inMicroseconds),
      targetUs: config.target.inMicroseconds,
      now: now,
      notifyBursts: onBurst != null,
      burstWindow: config.jankBurstWindow,
      burstCooldown: config.jankBurstCooldown,
    );
    if (onBurst == null) return;
    for (var i = 0; i < bursts; i++) {
      final fps = _snapshot.value.fps ?? config.refreshRate;
      try {
        onBurst(fps);
      } catch (e, st) {
        ISpect.logger.handle(
          exception: e,
          stackTrace: st,
          message: 'ISpectPerformanceOverlay.onJankBurst threw',
        );
      }
    }
  }

  void _logSevereJank(Iterable<FrameTiming> samples, Duration now) {
    final config = _config;
    final thresholdUs = (config.target.inMicroseconds * config.severeJankFactor)
        .round();
    for (final t in samples) {
      // Use the heaviest thread's work - `totalSpan` includes scheduling
      // wait time, which inflates in debug mode and idle UIs to false jank.
      final buildUs = t.buildDuration.inMicroseconds;
      final rasterUs = t.rasterDuration.inMicroseconds;
      final workUs = buildUs > rasterUs ? buildUs : rasterUs;
      if (workUs <= thresholdUs) continue;
      // Throttle: one entry per cooldown window. Without this a sustained
      // jank session (e.g. log viewer rebuilding itself on every new entry)
      // creates a feedback loop where each log triggers more frame work.
      if (!_sampler.claimJankLogSlot(
        now: now,
        cooldown: config.jankLogCooldown,
      )) {
        continue;
      }
      // No `stackTrace`: by the time `addTimingsCallback` fires the offending
      // frame is done - the current stack is engine code, not the cause.
      ISpect.logger.performanceJank(
        source: 'overlay',
        buildDuration: t.buildDuration,
        rasterDuration: t.rasterDuration,
        totalSpan: t.totalSpan,
        targetFrameTime: config.target,
      );
    }
  }

  void _resetSessionStats() {
    _sampler.reset();
    final current = _snapshot.value;
    _snapshot.value = _OverlaySnapshot(
      uiUs: current.uiUs,
      rasterUs: current.rasterUs,
      totalUs: current.totalUs,
      uiStats: current.uiStats,
      rasterStats: current.rasterStats,
      totalStats: current.totalStats,
      fps: current.fps,
      lastFramePerceptibleDrops: 0,
      allTimeMinFps: null,
      droppedFramesTotal: 0,
      rssBytes: _sampler.smoothedRssBytes,
      peakRssBytes: _sampler.peakRssBytes,
      baselineRssBytes: _sampler.baselineRssBytes,
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: _kOverlaySemanticsLabel,
    child: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ChartPainter(
                  snapshot: _snapshot,
                  config: _config,
                  paused: widget.paused,
                ),
              ),
            ),
          ),
        ),
        if (_config.allowFreeze)
          Positioned(
            top: 1,
            right: 1,
            child: _FreezeButton(
              paused: widget.paused,
              onTap: widget.onTogglePause,
              onLongPress: _resetSessionStats,
              color: _config.textColor,
            ),
          ),
      ],
    ),
  );
}

/// One painter for the whole overlay so per-frame updates repaint a single
/// render object instead of rebuilding a widget subtree - the listenable
/// passed to `super(repaint: ...)` drives invalidation directly from sample
/// updates.
class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.snapshot,
    required this.config,
    required this.paused,
  }) : _underBuffer = Float32List(config.sampleSize * 12),
       _overBuffer = Float32List(config.sampleSize * 12),
       _capBuffer = Float32List(config.sampleSize * 6),
       super(repaint: snapshot);

  final ValueListenable<_OverlaySnapshot> snapshot;
  final PerformanceOverlayConfig config;
  final bool paused;

  // Paints are mutated in place each frame; the loop never allocates one.
  final Paint _bgPaint = Paint();
  final Paint _barPaint = Paint();
  final Paint _gridPaint = Paint()..strokeWidth = 1;
  final Paint _capMarkerPaint = Paint();
  final Paint _dividerPaint = Paint();
  late final Paint _backplatePaint = Paint()
    ..color = config.backgroundColor.withValues(alpha: 0.7)
    ..style = PaintingStyle.fill;

  // Pre-allocated triangle buffers - one bar contributes 6 vertices
  // (12 floats), a capped notch adds 3 vertices. Reused across paints so
  // the per-frame draw call never grows a List<double> or copies into a
  // fresh Float32List.
  final Float32List _underBuffer;
  final Float32List _overBuffer;
  final Float32List _capBuffer;

  final TextPainter _headerPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  );
  final TextPainter _compactPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  );
  final TextPainter _uiStatsPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  final TextPainter _rasterStatsPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  final TextPainter _totalStatsPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  late final TextStyle _statsStyle = TextStyle(
    color: config.textColor,
    fontSize: _kStatsFontSize,
    height: _kStatsLineHeight,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  late final TextStyle _headerStyle = TextStyle(
    color: config.textColor.withValues(alpha: 0.85),
    fontSize: _kHeaderFontSize,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  late final TextStyle _headerBoldStyle = _headerStyle.copyWith(
    fontWeight: FontWeight.w700,
  );
  late final TextStyle _headerPausedStyle = _headerStyle.copyWith(
    color: config.textColor,
    fontWeight: FontWeight.w700,
  );
  late final TextStyle _overTargetStyle = TextStyle(
    color: config.overTargetColor,
  );
  late final TextStyle _uiLabelStyle = TextStyle(
    color: config.uiColor,
    fontWeight: FontWeight.w700,
  );
  late final TextStyle _rasterLabelStyle = TextStyle(
    color: config.rasterColor,
    fontWeight: FontWeight.w700,
  );
  late final TextStyle _totalLabelStyle = TextStyle(
    color: config.totalColor,
    fontWeight: FontWeight.w700,
  );
  late final TextStyle _compactPausedStyle = TextStyle(
    color: config.textColor.withValues(alpha: 0.7),
    fontWeight: FontWeight.w700,
  );
  // Lerp allocates; precompute the warn-tier colour and its dependent styles.
  late final Color _warnFpsColor =
      Color.lerp(config.textColor, config.overTargetColor, 0.55) ??
      config.overTargetColor;
  late final TextStyle _headerBoldWarnStyle = _headerBoldStyle.copyWith(
    color: _warnFpsColor,
  );
  late final TextStyle _headerBoldDangerStyle = _headerBoldStyle.copyWith(
    color: config.overTargetColor,
  );
  late final TextStyle _warnStyle = TextStyle(color: _warnFpsColor);

  late final Color _gridColor = config.textColor.withValues(alpha: 0.4);
  late final Color _gridColorSecondary = config.textColor.withValues(
    alpha: config.textColor.a * 0.4 * 0.4,
  );
  late final Color _capMarkerColor = config.textColor.withValues(alpha: 0.85);
  late final Color _dividerColor = config.textColor.withValues(alpha: 0.2);

  @override
  void paint(Canvas canvas, Size size) {
    final s = snapshot.value;
    final targetUs = config.target.inMicroseconds;
    _bgPaint.color = config.backgroundColor;
    canvas.drawRect(Offset.zero & size, _bgPaint);

    if (config.compact) {
      _paintCompact(canvas, size, s);
      return;
    }

    _paintHeader(canvas, Rect.fromLTWH(0, 0, size.width, _kHeaderHeight), s);

    const chartTop = _kHeaderHeight;
    final chartHeight = size.height - _kHeaderHeight;
    if (chartHeight <= 0 || size.width <= 2 * _kColumnDividerWidth) return;

    final columnWidth = (size.width - 2 * _kColumnDividerWidth) / 3;

    _dividerPaint.color = _dividerColor;
    canvas
      ..drawRect(
        Rect.fromLTWH(columnWidth, chartTop, _kColumnDividerWidth, chartHeight),
        _dividerPaint,
      )
      ..drawRect(
        Rect.fromLTWH(
          2 * columnWidth + _kColumnDividerWidth,
          chartTop,
          _kColumnDividerWidth,
          chartHeight,
        ),
        _dividerPaint,
      );

    _paintColumn(
      canvas: canvas,
      rect: Rect.fromLTWH(0, chartTop, columnWidth, chartHeight),
      samplesUs: s.uiUs,
      targetUs: targetUs,
      barColor: config.uiColor,
      stats: s.uiStats,
      statsPainter: _uiStatsPainter,
      labelText: 'UI',
      labelStyle: _uiLabelStyle,
    );
    _paintColumn(
      canvas: canvas,
      rect: Rect.fromLTWH(
        columnWidth + _kColumnDividerWidth,
        chartTop,
        columnWidth,
        chartHeight,
      ),
      samplesUs: s.rasterUs,
      targetUs: targetUs,
      barColor: config.rasterColor,
      stats: s.rasterStats,
      statsPainter: _rasterStatsPainter,
      labelText: 'Raster',
      labelStyle: _rasterLabelStyle,
    );
    _paintColumn(
      canvas: canvas,
      rect: Rect.fromLTWH(
        2 * (columnWidth + _kColumnDividerWidth),
        chartTop,
        columnWidth,
        chartHeight,
      ),
      samplesUs: s.totalUs,
      targetUs: targetUs,
      barColor: config.totalColor,
      stats: s.totalStats,
      statsPainter: _totalStatsPainter,
      labelText: 'Total',
      labelStyle: _totalLabelStyle,
    );
  }

  TextStyle _fpsHealthStyle(double? fps) {
    if (fps == null || config.refreshRate <= 0) return _headerBoldStyle;
    final ratio = fps / config.refreshRate;
    if (ratio >= _kFpsHealthyRatio) return _headerBoldStyle;
    if (ratio >= _kFpsWarningRatio) return _headerBoldWarnStyle;
    return _headerBoldDangerStyle;
  }

  /// Returns `null` when RSS is at or below `memoryWarnRatio × baseline`,
  /// so the default header/compact text style applies. Above warn → amber,
  /// above danger → overTargetColor.
  TextStyle? _memoryHealthStyle(int? rss, int? baseline) {
    if (rss == null || baseline == null || baseline <= 0) return null;
    final ratio = rss / baseline;
    if (ratio <= config.memoryWarnRatio) return null;
    if (ratio <= config.memoryDangerRatio) return _warnStyle;
    return _overTargetStyle;
  }

  void _paintHeader(Canvas canvas, Rect rect, _OverlaySnapshot s) {
    _headerPainter.text = TextSpan(
      style: _headerStyle,
      children: [
        TextSpan(text: '${config.refreshRate.toStringAsFixed(0)}Hz · '),
        TextSpan(
          text: '${s.fps?.toStringAsFixed(1) ?? '--'} FPS',
          style: _fpsHealthStyle(s.fps),
        ),
        if (config.showMemory && s.rssBytes != null)
          TextSpan(
            text: ' · ${_formatMb(s.rssBytes!)} MB',
            style: _memoryHealthStyle(s.rssBytes, s.baselineRssBytes),
          ),
        if (s.lastFramePerceptibleDrops > 0)
          TextSpan(
            text: ' · +${s.lastFramePerceptibleDrops}',
            style: _overTargetStyle,
          ),
        if (!config.showAllTimeStats && s.droppedFramesTotal > 0)
          TextSpan(
            text: ' · ${s.droppedFramesTotal} drops',
            style: _overTargetStyle,
          ),
        if (config.showAllTimeStats) ..._allTimeStatsSpans(s),
        if (paused) TextSpan(text: '  · PAUSED', style: _headerPausedStyle),
      ],
    );
    final maxWidth = (rect.width - _kHeaderPadding.horizontal).clamp(
      0.0,
      double.infinity,
    );
    _headerPainter.layout(maxWidth: maxWidth);
    final y = rect.top + (rect.height - _headerPainter.height) / 2;
    final origin = Offset(rect.left + _kHeaderPadding.left, y);
    _paintTextBackplate(canvas, _headerPainter, origin);
    _headerPainter.paint(canvas, origin);
  }

  static const double _kBackplateInflateX = 3;
  static const double _kBackplateInflateY = 1;
  static const Radius _kBackplateRadius = Radius.circular(3);

  void _paintTextBackplate(Canvas canvas, TextPainter painter, Offset offset) {
    final rect = Rect.fromLTWH(
      offset.dx - _kBackplateInflateX,
      offset.dy - _kBackplateInflateY,
      painter.width + _kBackplateInflateX * 2,
      painter.height + _kBackplateInflateY * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, _kBackplateRadius),
      _backplatePaint,
    );
  }

  Iterable<TextSpan> _allTimeStatsSpans(_OverlaySnapshot s) sync* {
    final min = s.allTimeMinFps;
    if (min != null) yield TextSpan(text: ' · min ${min.toStringAsFixed(0)}');
    if (s.droppedFramesTotal > 0 && s.lastFramePerceptibleDrops == 0) {
      yield TextSpan(
        text: ' · drop ${s.droppedFramesTotal}',
        style: _overTargetStyle,
      );
    }
    if (config.showMemory && s.baselineRssBytes != null) {
      yield TextSpan(text: ' · base ${_formatMb(s.baselineRssBytes!)}MB');
    }
    if (config.showMemory && s.peakRssBytes != null) {
      yield TextSpan(text: ' · peak ${_formatMb(s.peakRssBytes!)}MB');
    }
  }

  void _paintCompact(Canvas canvas, Size size, _OverlaySnapshot s) {
    final uiStats = s.uiStats;
    final rasterStats = s.rasterStats;
    final totalStats = s.totalStats;
    // Summing per-thread counts would triple-count the same dropped frame;
    // totalSpan is the user-visible "frame missed" signal.
    final jankTotal = totalStats.jankCount;

    TextSpan metric(
      String label,
      TextStyle labelStyle,
      PerformanceChartStats stats,
    ) => TextSpan(
      children: [
        TextSpan(text: label, style: labelStyle),
        TextSpan(
          text: ' ${_formatMs(stats.avg)}/${_formatMs(stats.p99)}ms ',
          style: stats.p99 > config.target ? _overTargetStyle : null,
        ),
        const TextSpan(text: '· '),
      ],
    );

    _compactPainter.text = TextSpan(
      style: _statsStyle,
      children: [
        TextSpan(text: '${config.refreshRate.toStringAsFixed(0)}Hz · '),
        TextSpan(
          text: '${s.fps?.toStringAsFixed(1) ?? '--'} FPS ',
          style: _fpsHealthStyle(s.fps),
        ),
        const TextSpan(text: '· '),
        metric('UI', _uiLabelStyle, uiStats),
        metric('R', _rasterLabelStyle, rasterStats),
        metric('T', _totalLabelStyle, totalStats),
        TextSpan(
          text: '$jankTotal jank',
          style: jankTotal > 0 ? _overTargetStyle : null,
        ),
        if (config.showMemory && s.rssBytes != null)
          TextSpan(
            text: ' · ${_formatMb(s.rssBytes!)}MB',
            style: _memoryHealthStyle(s.rssBytes, s.baselineRssBytes),
          ),
        if (config.showAllTimeStats) ..._allTimeStatsSpans(s),
        if (paused) TextSpan(text: '  · PAUSED', style: _compactPausedStyle),
      ],
    );
    final maxWidth = (size.width - _kCompactPadding.horizontal).clamp(
      0.0,
      double.infinity,
    );
    _compactPainter.layout(maxWidth: maxWidth);
    final origin = Offset(_kCompactPadding.left, _kCompactPadding.top);
    _paintTextBackplate(canvas, _compactPainter, origin);
    _compactPainter.paint(canvas, origin);
  }

  void _paintColumn({
    required Canvas canvas,
    required Rect rect,
    required List<int> samplesUs,
    required int targetUs,
    required Color barColor,
    required PerformanceChartStats stats,
    required TextPainter statsPainter,
    required String labelText,
    required TextStyle labelStyle,
  }) {
    _paintBars(canvas, rect, samplesUs, targetUs, barColor);
    _paintGrid(canvas, rect);
    _paintStatsText(
      canvas: canvas,
      rect: rect,
      stats: stats,
      statsPainter: statsPainter,
      labelText: labelText,
      labelStyle: labelStyle,
    );
  }

  void _paintBars(
    Canvas canvas,
    Rect rect,
    List<int> samplesUs,
    int targetUs,
    Color barColor,
  ) {
    final rangeUs = config.barRangeMax.inMicroseconds;
    if (rangeUs <= 0 || samplesUs.isEmpty || config.sampleSize <= 0) return;

    final slotWidth = rect.width / config.sampleSize;
    final barWidth = (slotWidth - _kBarGap).clamp(1.0, slotWidth);

    // Two vertex batches per column (under-target colour + over-target colour)
    // collapse up to `sampleSize` drawRect calls into 2 drawVertices calls,
    // plus a third batch for the small "off-chart" notches on capped bars.
    var underLen = 0;
    var overLen = 0;
    var capLen = 0;

    for (var i = config.sampleSize - 1; i >= 0; i--) {
      final index = i - config.sampleSize + samplesUs.length;
      if (index < 0) break;
      final us = samplesUs[index];
      final isCapped = us > rangeUs;
      final heightFactor = (us / rangeUs).clamp(0.0, 1.0);
      final left = rect.left + i * slotWidth;
      final right = left + barWidth;
      final top = rect.bottom - rect.height * heightFactor;
      final bottom = rect.bottom;

      if (us <= targetUs) {
        underLen = _writeBarQuad(
          _underBuffer,
          underLen,
          left,
          top,
          right,
          bottom,
        );
      } else {
        overLen = _writeBarQuad(_overBuffer, overLen, left, top, right, bottom);
      }

      if (isCapped) {
        final centerX = left + barWidth / 2;
        final notchBase = rect.top + _kCapMarkerHeight;
        capLen = _writeCapTri(
          _capBuffer,
          capLen,
          centerX,
          rect.top,
          left,
          right,
          notchBase,
        );
      }
    }

    if (underLen > 0) {
      _barPaint.color = barColor;
      _drawTriangleBatch(canvas, _underBuffer, underLen, _barPaint);
    }
    if (overLen > 0) {
      _barPaint.color = config.overTargetColor;
      _drawTriangleBatch(canvas, _overBuffer, overLen, _barPaint);
    }
    if (capLen > 0) {
      _capMarkerPaint.color = _capMarkerColor;
      _drawTriangleBatch(canvas, _capBuffer, capLen, _capMarkerPaint);
    }
  }

  static int _writeBarQuad(
    Float32List buf,
    int i,
    double left,
    double top,
    double right,
    double bottom,
  ) {
    buf[i] = left;
    buf[i + 1] = top;
    buf[i + 2] = right;
    buf[i + 3] = top;
    buf[i + 4] = left;
    buf[i + 5] = bottom;
    buf[i + 6] = right;
    buf[i + 7] = top;
    buf[i + 8] = right;
    buf[i + 9] = bottom;
    buf[i + 10] = left;
    buf[i + 11] = bottom;
    return i + 12;
  }

  static int _writeCapTri(
    Float32List buf,
    int i,
    double cx,
    double yTop,
    double left,
    double right,
    double notchBase,
  ) {
    buf[i] = cx;
    buf[i + 1] = yTop;
    buf[i + 2] = left;
    buf[i + 3] = notchBase;
    buf[i + 4] = right;
    buf[i + 5] = notchBase;
    return i + 6;
  }

  static void _drawTriangleBatch(
    Canvas canvas,
    Float32List buffer,
    int length,
    Paint paint,
  ) {
    final positions = length == buffer.length
        ? buffer
        : Float32List.sublistView(buffer, 0, length);
    final vertices = Vertices.raw(VertexMode.triangles, positions);
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    vertices.dispose();
  }

  void _paintGrid(Canvas canvas, Rect rect) {
    final rangeUs = config.barRangeMax.inMicroseconds;
    if (rangeUs <= 0) return;
    for (var multiple = 1; multiple <= 4; multiple++) {
      final yUs = config.target.inMicroseconds * multiple;
      if (yUs > rangeUs) break;
      final factor = yUs / rangeUs;
      final y = rect.bottom - rect.height * factor;
      _gridPaint.color = multiple == 1 ? _gridColor : _gridColorSecondary;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), _gridPaint);
    }
  }

  void _paintStatsText({
    required Canvas canvas,
    required Rect rect,
    required PerformanceChartStats stats,
    required TextPainter statsPainter,
    required String labelText,
    required TextStyle labelStyle,
  }) {
    statsPainter.text = TextSpan(
      style: _statsStyle,
      children: <TextSpan>[
        TextSpan(text: labelText, style: labelStyle),
        TextSpan(
          text: '  ${stats.jankCount} jank\n',
          style: stats.jankCount > 0 ? _overTargetStyle : null,
        ),
        TextSpan(
          text: 'avg ${_formatMs(stats.avg)}ms\n',
          style: stats.avg > config.target ? _overTargetStyle : null,
        ),
        if (config.showP90)
          TextSpan(
            text: 'p90 ${_formatMs(stats.p90)}ms\n',
            style: stats.p90 > config.target ? _overTargetStyle : null,
          ),
        TextSpan(
          text: 'p99 ${_formatMs(stats.p99)}ms',
          style: stats.p99 > config.target ? _overTargetStyle : null,
        ),
      ],
    );
    final maxWidth = (rect.width - _kStatsPadding.horizontal).clamp(
      0.0,
      double.infinity,
    );
    statsPainter.layout(maxWidth: maxWidth);
    final origin = Offset(
      rect.left + _kStatsPadding.left,
      rect.top + _kStatsPadding.top,
    );
    _paintTextBackplate(canvas, statsPainter, origin);
    statsPainter.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.snapshot != snapshot || old.config != config || old.paused != paused;
}

/// Sits outside the overlay's `IgnorePointer` so taps land here while the
/// rest of the chart stays transparent to gestures.
class _FreezeButton extends StatelessWidget {
  const _FreezeButton({
    required this.paused,
    required this.onTap,
    required this.onLongPress,
    required this.color,
  });

  final bool paused;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: paused ? 'Resume performance overlay' : 'Pause performance overlay',
    onLongPressHint: 'Reset session stats',
    child: SizedBox(
      width: _kPauseButtonSize,
      height: _kPauseButtonSize,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: onTap,
          onLongPress: onLongPress,
          radius: _kPauseButtonSize,
          child: Center(
            child: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 14,
              color: color,
            ),
          ),
        ),
      ),
    ),
  );
}

String _formatMs(Duration d) => (d.inMicroseconds / 1e3).toStringAsFixed(1);

String _formatMb(int bytes) {
  final mb = bytes / (1024 * 1024);
  return mb >= 100 ? mb.toStringAsFixed(0) : mb.toStringAsFixed(1);
}
