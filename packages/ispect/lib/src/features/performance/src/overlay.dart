import 'dart:typed_data';
import 'dart:ui' show VertexMode, Vertices;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ispect/src/features/performance/src/stats.dart';
import 'package:ispect/src/ispect.dart';
import 'package:ispectify/ispectify.dart';

/// Lets consumers filter jank events in the log viewer by the dedicated
/// `performance-jank` log key instead of grepping `warning`-level strings.
const ISpectTraceCategory kPerformanceTraceCategory = ISpectTraceCategory(
  id: 'performance',
  successKey: 'performance-jank',
  errorKey: 'performance-error',
);

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
const EdgeInsets _kHeaderPadding =
    EdgeInsets.symmetric(horizontal: 6, vertical: 1);
const EdgeInsets _kCompactPadding =
    EdgeInsets.symmetric(horizontal: 6, vertical: 4);

const String _kOverlaySemanticsLabel = 'Performance overlay';

/// Discards startup spikes (JIT, asset decode, shader cache) from session
/// min FPS and drop counter.
const Duration _kWarmupDuration = Duration(milliseconds: 800);

const double _kFpsHealthyRatio = 0.95;
const double _kFpsWarningRatio = 0.80;

/// The default overlay is not color-blind safe. Opt in by passing each
/// `colorBlind*` value into the matching overlay parameter — including
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

/// Cross-platform performance overlay built on [FrameTiming] — works on web
/// and desktop where Flutter's native [PerformanceOverlay] does not.
///
/// UI build and raster are each checked against the full frame target (not
/// half) because the two threads pipeline across frames. The "8ms + 8ms"
/// split in the Flutter docs is about input-to-display latency, not jank.
///
/// As with Flutter's native overlay, the readings are only meaningful in
/// profile mode — debug-mode asserts and JIT inflate frame work, so numbers
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
    this.showAllTimeStats = false,
    this.onJankBurst,
    this.jankBurstWindow = 3,
    this.jankBurstCooldown = const Duration(seconds: 1),
  })  : assert(severeJankFactor >= 1.0, 'severeJankFactor must be >= 1'),
        assert(sampleSize > 0, 'sampleSize must be > 0'),
        assert(jankBurstWindow > 0, 'jankBurstWindow must be > 0');

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
  /// frames — both threads independently get the full per-frame budget.
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
  /// Invoked synchronously from `SchedulerBinding.addTimingsCallback` — keep
  /// the body in microseconds or defer work to a post-frame callback /
  /// isolate. Exceptions are caught and routed through [ISpect.logger] so
  /// they do not poison the engine's timings dispatch.
  final void Function(FrameTiming timing)? onFrameTiming;

  /// Log frames where `totalSpan > targetFrameTime × severeJankFactor` via
  /// [ISpect.logger]. Off by default to avoid log spam.
  final bool enableJankLogging;

  /// `2.0` matches "visible hitch" on 60Hz; below `1.0` would log every
  /// frame above target.
  final double severeJankFactor;

  /// Append session-wide `min · drop` figures next to the FPS reading.
  final bool showAllTimeStats;

  /// Fires after [jankBurstWindow] consecutive over-target frames, throttled
  /// by [jankBurstCooldown]. Runs on the engine's timings dispatch — keep
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
        paused: _paused,
        onTogglePause: _togglePause,
        onFrameTiming: widget.onFrameTiming,
        enableJankLogging: widget.enableJankLogging,
        severeJankFactor: widget.severeJankFactor,
        showAllTimeStats: widget.showAllTimeStats,
        onJankBurst: widget.onJankBurst,
        jankBurstWindow: widget.jankBurstWindow,
        jankBurstCooldown: widget.jankBurstCooldown,
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

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Align(
            alignment: widget.alignment,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: RepaintBoundary(child: overlay),
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
    required this.lastFrameMissedVsyncs,
    required this.allTimeMinFps,
    required this.droppedFramesTotal,
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
  final int lastFrameMissedVsyncs;

  final double? allTimeMinFps;

  final int droppedFramesTotal;

  static const _OverlaySnapshot empty = _OverlaySnapshot(
    uiUs: <int>[],
    rasterUs: <int>[],
    totalUs: <int>[],
    uiStats: PerformanceChartStats.zero,
    rasterStats: PerformanceChartStats.zero,
    totalStats: PerformanceChartStats.zero,
    fps: null,
    lastFrameMissedVsyncs: 0,
    allTimeMinFps: null,
    droppedFramesTotal: 0,
  );
}

class _OverlayBody extends StatefulWidget {
  const _OverlayBody({
    required this.sampleSize,
    required this.target,
    required this.refreshRate,
    required this.barRangeMax,
    required this.backgroundColor,
    required this.textColor,
    required this.uiColor,
    required this.rasterColor,
    required this.totalColor,
    required this.overTargetColor,
    required this.compact,
    required this.showP90,
    required this.allowFreeze,
    required this.paused,
    required this.onTogglePause,
    required this.onFrameTiming,
    required this.enableJankLogging,
    required this.severeJankFactor,
    required this.showAllTimeStats,
    required this.onJankBurst,
    required this.jankBurstWindow,
    required this.jankBurstCooldown,
  });

  final int sampleSize;
  final Duration target;
  final double refreshRate;
  final Duration barRangeMax;
  final Color backgroundColor;
  final Color textColor;
  final Color uiColor;
  final Color rasterColor;
  final Color totalColor;
  final Color overTargetColor;
  final bool compact;
  final bool showP90;
  final bool allowFreeze;
  final bool paused;
  final VoidCallback onTogglePause;
  final void Function(FrameTiming timing)? onFrameTiming;
  final bool enableJankLogging;
  final double severeJankFactor;
  final bool showAllTimeStats;
  final void Function(double currentFps)? onJankBurst;
  final int jankBurstWindow;
  final Duration jankBurstCooldown;

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
  final Stopwatch _warmupTimer = Stopwatch();

  double _allTimeMinFps = double.infinity;
  int _droppedFramesTotal = 0;
  int _lastFrameMissedVsyncs = 0;
  int _consecutiveJankCount = 0;
  final Stopwatch _jankBurstCooldown = Stopwatch();

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

  bool get _warmupCompleted =>
      _warmupTimer.elapsedMilliseconds >= _kWarmupDuration.inMilliseconds;

  void _timingsCallback(List<FrameTiming> frameTimings) {
    if (!mounted) return;

    final newSamples = _skippedFirstSample
        ? frameTimings
        : frameTimings.length > 1
            ? frameTimings.sublist(1)
            : const <FrameTiming>[];
    _skippedFirstSample = true;

    if (newSamples.isEmpty) return;
    if (!_warmupTimer.isRunning) _warmupTimer.start();

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
    if (widget.enableJankLogging) {
      _logSevereJank(newSamples);
    }
    _trackJankBurst(newSamples);

    if (widget.paused) return;

    final targetUs = widget.target.inMicroseconds;
    for (final t in newSamples) {
      _uiUs.add(t.buildDuration.inMicroseconds);
      _rasterUs.add(t.rasterDuration.inMicroseconds);
      _totalUs.add(t.totalSpan.inMicroseconds);
    }
    _trimToWindow(_uiUs);
    _trimToWindow(_rasterUs);
    _trimToWindow(_totalUs);

    final fps = computeSmoothFps(_totalUs, widget.refreshRate);
    if (_warmupCompleted && fps != null && fps > 0 && fps < _allTimeMinFps) {
      _allTimeMinFps = fps;
    }

    _snapshot.value = _OverlaySnapshot(
      uiUs: List<int>.of(_uiUs),
      rasterUs: List<int>.of(_rasterUs),
      totalUs: List<int>.of(_totalUs),
      uiStats: PerformanceChartStats.fromMicroseconds(_uiUs, targetUs),
      rasterStats: PerformanceChartStats.fromMicroseconds(_rasterUs, targetUs),
      totalStats: PerformanceChartStats.fromMicroseconds(_totalUs, targetUs),
      fps: fps,
      lastFrameMissedVsyncs: _lastFrameMissedVsyncs,
      allTimeMinFps: _allTimeMinFps == double.infinity ? null : _allTimeMinFps,
      droppedFramesTotal: _droppedFramesTotal,
    );
  }

  void _trimToWindow(List<int> buffer) {
    final overflow = buffer.length - widget.sampleSize;
    if (overflow > 0) buffer.removeRange(0, overflow);
  }

  void _trackJankBurst(Iterable<FrameTiming> samples) {
    final targetUs = widget.target.inMicroseconds;
    final onBurst = widget.onJankBurst;
    final cooldownMs = widget.jankBurstCooldown.inMilliseconds;
    final warmedUp = _warmupCompleted;
    var lastPerceptible = 0;
    for (final t in samples) {
      final totalUs = t.totalSpan.inMicroseconds;
      final missed = missedVsyncs(totalUs, targetUs);
      final perceptible = perceptibleDrops(totalUs, targetUs);
      lastPerceptible = perceptible;
      if (missed > 0) {
        if (warmedUp) _droppedFramesTotal += perceptible;
        _consecutiveJankCount++;
        if (warmedUp &&
            onBurst != null &&
            _consecutiveJankCount >= widget.jankBurstWindow &&
            (!_jankBurstCooldown.isRunning ||
                _jankBurstCooldown.elapsedMilliseconds >= cooldownMs)) {
          _jankBurstCooldown
            ..reset()
            ..start();
          final fps = _snapshot.value.fps ?? widget.refreshRate;
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
      } else {
        _consecutiveJankCount = 0;
      }
    }
    _lastFrameMissedVsyncs = lastPerceptible;
  }

  void _logSevereJank(Iterable<FrameTiming> samples) {
    final thresholdUs =
        (widget.target.inMicroseconds * widget.severeJankFactor).round();
    final threshold = Duration(microseconds: thresholdUs);
    final targetMs = _formatMs(widget.target);
    for (final t in samples) {
      if (t.totalSpan <= threshold) continue;
      ISpect.logger.traceCategory(
        category: kPerformanceTraceCategory,
        source: 'overlay',
        operation: 'jank',
        duration: t.totalSpan,
        meta: <String, Object?>{
          'ui_ms': _formatMs(t.buildDuration),
          'raster_ms': _formatMs(t.rasterDuration),
          'total_ms': _formatMs(t.totalSpan),
          'target_ms': targetMs,
        },
        consoleMessage: 'Performance jank: total ${_formatMs(t.totalSpan)}ms '
            '(UI ${_formatMs(t.buildDuration)}ms · '
            'raster ${_formatMs(t.rasterDuration)}ms · '
            'target ${targetMs}ms)',
      );
    }
  }

  void _resetSessionStats() {
    _allTimeMinFps = double.infinity;
    _droppedFramesTotal = 0;
    _lastFrameMissedVsyncs = 0;
    _consecutiveJankCount = 0;
    _jankBurstCooldown
      ..stop()
      ..reset();
    final current = _snapshot.value;
    _snapshot.value = _OverlaySnapshot(
      uiUs: current.uiUs,
      rasterUs: current.rasterUs,
      totalUs: current.totalUs,
      uiStats: current.uiStats,
      rasterStats: current.rasterStats,
      totalStats: current.totalStats,
      fps: current.fps,
      lastFrameMissedVsyncs: 0,
      allTimeMinFps: null,
      droppedFramesTotal: 0,
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
                      sampleSize: widget.sampleSize,
                      target: widget.target,
                      refreshRate: widget.refreshRate,
                      barRangeMax: widget.barRangeMax,
                      backgroundColor: widget.backgroundColor,
                      textColor: widget.textColor,
                      uiColor: widget.uiColor,
                      rasterColor: widget.rasterColor,
                      totalColor: widget.totalColor,
                      overTargetColor: widget.overTargetColor,
                      compact: widget.compact,
                      showP90: widget.showP90,
                      showAllTimeStats: widget.showAllTimeStats,
                      paused: widget.paused,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.allowFreeze)
              Positioned(
                top: 1,
                right: 1,
                child: _FreezeButton(
                  paused: widget.paused,
                  onTap: widget.onTogglePause,
                  onLongPress: _resetSessionStats,
                  color: widget.textColor,
                ),
              ),
          ],
        ),
      );
}

/// One painter for the whole overlay so per-frame updates repaint a single
/// render object instead of rebuilding a widget subtree — the listenable
/// passed to `super(repaint: ...)` drives invalidation directly from sample
/// updates.
class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.snapshot,
    required this.sampleSize,
    required this.target,
    required this.refreshRate,
    required this.barRangeMax,
    required this.backgroundColor,
    required this.textColor,
    required this.uiColor,
    required this.rasterColor,
    required this.totalColor,
    required this.overTargetColor,
    required this.compact,
    required this.showP90,
    required this.showAllTimeStats,
    required this.paused,
  }) : super(repaint: snapshot);

  final ValueListenable<_OverlaySnapshot> snapshot;
  final int sampleSize;
  final Duration target;
  final double refreshRate;
  final Duration barRangeMax;
  final Color backgroundColor;
  final Color textColor;
  final Color uiColor;
  final Color rasterColor;
  final Color totalColor;
  final Color overTargetColor;
  final bool compact;
  final bool showP90;
  final bool showAllTimeStats;
  final bool paused;

  // Paints are mutated in place each frame; the loop never allocates one.
  final Paint _bgPaint = Paint();
  final Paint _barPaint = Paint();
  final Paint _gridPaint = Paint()..strokeWidth = 1;
  final Paint _capMarkerPaint = Paint();
  final Paint _dividerPaint = Paint();

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
  final TextPainter _uiStatsPainter =
      TextPainter(textDirection: TextDirection.ltr);
  final TextPainter _rasterStatsPainter =
      TextPainter(textDirection: TextDirection.ltr);
  final TextPainter _totalStatsPainter =
      TextPainter(textDirection: TextDirection.ltr);

  late final TextStyle _statsStyle = TextStyle(
    color: textColor,
    fontSize: _kStatsFontSize,
    height: _kStatsLineHeight,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  late final TextStyle _headerStyle = TextStyle(
    color: textColor.withValues(alpha: 0.85),
    fontSize: _kHeaderFontSize,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  late final TextStyle _headerBoldStyle =
      _headerStyle.copyWith(fontWeight: FontWeight.w700);
  late final TextStyle _headerPausedStyle = _headerStyle.copyWith(
    color: textColor,
    fontWeight: FontWeight.w700,
  );
  late final TextStyle _overTargetStyle = TextStyle(color: overTargetColor);
  late final TextStyle _uiLabelStyle =
      TextStyle(color: uiColor, fontWeight: FontWeight.w700);
  late final TextStyle _rasterLabelStyle =
      TextStyle(color: rasterColor, fontWeight: FontWeight.w700);
  late final TextStyle _totalLabelStyle =
      TextStyle(color: totalColor, fontWeight: FontWeight.w700);
  late final TextStyle _compactPausedStyle = TextStyle(
    color: textColor.withValues(alpha: 0.7),
    fontWeight: FontWeight.w700,
  );
  // Lerp allocates; precompute the warn-tier colour and its dependent styles.
  late final Color _warnFpsColor =
      Color.lerp(textColor, overTargetColor, 0.55) ?? overTargetColor;
  late final TextStyle _headerBoldWarnStyle =
      _headerBoldStyle.copyWith(color: _warnFpsColor);
  late final TextStyle _headerBoldDangerStyle =
      _headerBoldStyle.copyWith(color: overTargetColor);

  late final Color _gridColor = textColor.withValues(alpha: 0.4);
  late final Color _gridColorSecondary =
      textColor.withValues(alpha: textColor.a * 0.4 * 0.4);
  late final Color _capMarkerColor = textColor.withValues(alpha: 0.85);
  late final Color _dividerColor = textColor.withValues(alpha: 0.2);

  @override
  void paint(Canvas canvas, Size size) {
    final s = snapshot.value;
    final targetUs = target.inMicroseconds;
    _bgPaint.color = backgroundColor;
    canvas.drawRect(Offset.zero & size, _bgPaint);

    if (compact) {
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
      barColor: uiColor,
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
      barColor: rasterColor,
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
      barColor: totalColor,
      stats: s.totalStats,
      statsPainter: _totalStatsPainter,
      labelText: 'Total',
      labelStyle: _totalLabelStyle,
    );
  }

  TextStyle _fpsHealthStyle(double? fps) {
    if (fps == null || refreshRate <= 0) return _headerBoldStyle;
    final ratio = fps / refreshRate;
    if (ratio >= _kFpsHealthyRatio) return _headerBoldStyle;
    if (ratio >= _kFpsWarningRatio) return _headerBoldWarnStyle;
    return _headerBoldDangerStyle;
  }

  void _paintHeader(Canvas canvas, Rect rect, _OverlaySnapshot s) {
    _headerPainter.text = TextSpan(
      style: _headerStyle,
      children: [
        TextSpan(text: '${refreshRate.toStringAsFixed(0)}Hz · '),
        TextSpan(
          text: '${s.fps?.toStringAsFixed(1) ?? '--'} FPS',
          style: _fpsHealthStyle(s.fps),
        ),
        if (s.lastFrameMissedVsyncs > 0)
          TextSpan(
            text: ' · +${s.lastFrameMissedVsyncs} missed',
            style: _overTargetStyle,
          )
        else if (!showAllTimeStats && s.droppedFramesTotal > 0)
          TextSpan(
            text: ' · ${s.droppedFramesTotal} drops',
            style: _overTargetStyle,
          ),
        if (showAllTimeStats) ..._allTimeStatsSpans(s),
        if (paused) TextSpan(text: '  · PAUSED', style: _headerPausedStyle),
      ],
    );
    final maxWidth =
        (rect.width - _kHeaderPadding.horizontal).clamp(0.0, double.infinity);
    _headerPainter.layout(maxWidth: maxWidth);
    final y = rect.top + (rect.height - _headerPainter.height) / 2;
    _headerPainter.paint(canvas, Offset(rect.left + _kHeaderPadding.left, y));
  }

  Iterable<TextSpan> _allTimeStatsSpans(_OverlaySnapshot s) sync* {
    final min = s.allTimeMinFps;
    if (min != null) yield TextSpan(text: ' · min ${min.toStringAsFixed(0)}');
    if (s.droppedFramesTotal > 0 && s.lastFrameMissedVsyncs == 0) {
      yield TextSpan(
        text: ' · drop ${s.droppedFramesTotal}',
        style: _overTargetStyle,
      );
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
    ) =>
        TextSpan(
          children: [
            TextSpan(text: label, style: labelStyle),
            TextSpan(
              text: ' ${_formatMs(stats.avg)}/${_formatMs(stats.p99)}ms ',
              style: stats.p99 > target ? _overTargetStyle : null,
            ),
            const TextSpan(text: '· '),
          ],
        );

    _compactPainter.text = TextSpan(
      style: _statsStyle,
      children: [
        TextSpan(text: '${refreshRate.toStringAsFixed(0)}Hz · '),
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
        if (showAllTimeStats) ..._allTimeStatsSpans(s),
        if (paused) TextSpan(text: '  · PAUSED', style: _compactPausedStyle),
      ],
    );
    final maxWidth =
        (size.width - _kCompactPadding.horizontal).clamp(0.0, double.infinity);
    _compactPainter
      ..layout(maxWidth: maxWidth)
      ..paint(
        canvas,
        Offset(_kCompactPadding.left, _kCompactPadding.top),
      );
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
    final rangeUs = barRangeMax.inMicroseconds;
    if (rangeUs <= 0 || samplesUs.isEmpty || sampleSize <= 0) return;

    final slotWidth = rect.width / sampleSize;
    final barWidth = (slotWidth - _kBarGap).clamp(1.0, slotWidth);

    // Two vertex batches per column (under-target colour + over-target colour)
    // collapse up to `sampleSize` drawRect calls into 2 drawVertices calls,
    // plus a third batch for the small "off-chart" notches on capped bars.
    final under = <double>[];
    final over = <double>[];
    final caps = <double>[];

    for (var i = sampleSize - 1; i >= 0; i--) {
      final index = i - sampleSize + samplesUs.length;
      if (index < 0) break;
      final us = samplesUs[index];
      final isCapped = us > rangeUs;
      final heightFactor = (us / rangeUs).clamp(0.0, 1.0);
      final left = rect.left + i * slotWidth;
      final right = left + barWidth;
      final top = rect.bottom - rect.height * heightFactor;
      final bottom = rect.bottom;

      (us <= targetUs ? under : over)
        ..add(left)
        ..add(top)
        ..add(right)
        ..add(top)
        ..add(left)
        ..add(bottom)
        ..add(right)
        ..add(top)
        ..add(right)
        ..add(bottom)
        ..add(left)
        ..add(bottom);

      if (isCapped) {
        final centerX = left + barWidth / 2;
        final notchBase = rect.top + _kCapMarkerHeight;
        caps
          ..add(centerX)
          ..add(rect.top)
          ..add(left)
          ..add(notchBase)
          ..add(right)
          ..add(notchBase);
      }
    }

    if (under.isNotEmpty) {
      _barPaint.color = barColor;
      _drawTriangleBatch(canvas, under, _barPaint);
    }
    if (over.isNotEmpty) {
      _barPaint.color = overTargetColor;
      _drawTriangleBatch(canvas, over, _barPaint);
    }
    if (caps.isNotEmpty) {
      _capMarkerPaint.color = _capMarkerColor;
      _drawTriangleBatch(canvas, caps, _capMarkerPaint);
    }
  }

  static void _drawTriangleBatch(
    Canvas canvas,
    List<double> positions,
    Paint paint,
  ) {
    final vertices = Vertices.raw(
      VertexMode.triangles,
      Float32List.fromList(positions),
    );
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    vertices.dispose();
  }

  void _paintGrid(Canvas canvas, Rect rect) {
    final rangeUs = barRangeMax.inMicroseconds;
    if (rangeUs <= 0) return;
    for (var multiple = 1; multiple <= 4; multiple++) {
      final yUs = target.inMicroseconds * multiple;
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
          style: stats.avg > target ? _overTargetStyle : null,
        ),
        if (showP90)
          TextSpan(
            text: 'p90 ${_formatMs(stats.p90)}ms\n',
            style: stats.p90 > target ? _overTargetStyle : null,
          ),
        TextSpan(
          text: 'p99 ${_formatMs(stats.p99)}ms',
          style: stats.p99 > target ? _overTargetStyle : null,
        ),
      ],
    );
    final maxWidth =
        (rect.width - _kStatsPadding.horizontal).clamp(0.0, double.infinity);
    statsPainter
      ..layout(maxWidth: maxWidth)
      ..paint(
        canvas,
        Offset(rect.left + _kStatsPadding.left, rect.top + _kStatsPadding.top),
      );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.snapshot != snapshot ||
      old.target != target ||
      old.refreshRate != refreshRate ||
      old.barRangeMax != barRangeMax ||
      old.backgroundColor != backgroundColor ||
      old.textColor != textColor ||
      old.uiColor != uiColor ||
      old.rasterColor != rasterColor ||
      old.totalColor != totalColor ||
      old.overTargetColor != overTargetColor ||
      old.compact != compact ||
      old.showP90 != showP90 ||
      old.showAllTimeStats != showAllTimeStats ||
      old.paused != paused ||
      old.sampleSize != sampleSize;
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
        label:
            paused ? 'Resume performance overlay' : 'Pause performance overlay',
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
