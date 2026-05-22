import 'dart:ui' show FramePhase;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ispect/src/features/performance/src/stats.dart';
import 'package:ispect/src/ispect.dart';

/// Default fallback display refresh rate (Hz) when [View.display.refreshRate]
/// is unavailable. 60Hz ⇒ ~16.67ms target frame time.
const double _kFallbackRefreshRate = 60;

/// Horizontal gap reserved between bars, in logical pixels.
const double _kBarGap = 1;

/// Height of the header row (refresh-rate + delivered FPS + freeze button).
const double _kHeaderHeight = 16;

/// Width/height of the freeze toggle button.
const double _kPauseButtonSize = 18;

/// Font sizes.
const double _kStatsFontSize = 10;
const double _kHeaderFontSize = 9;
const double _kStatsLineHeight = 1.15;

/// Color palettes that consumers can copy into the overlay's individual color
/// parameters.
///
/// The default overlay uses Material teal/blue/purple plus a saturated red
/// for over-target frames; that combination is not safe under all color
/// vision deficiencies. To opt into the Wong/Okabe color-blind safe palette,
/// pass each `colorBlind*` constant into the matching overlay parameter —
/// including [colorBlindOverTarget], which the default `overTargetColor`
/// does not pick up automatically.
abstract final class ISpectPerformanceOverlayPalettes {
  /// Default palette (Material teal/blue/purple).
  static const ui = Colors.teal;
  static const raster = Colors.blue;
  static const total = Colors.purple;

  /// Color-blind safe palette using the Wong/Okabe set (distinguishable across
  /// deuteranopia, protanopia, and tritanopia).
  static const colorBlindUi = Color(0xFF009E73);
  static const colorBlindRaster = Color(0xFFE69F00);
  static const colorBlindTotal = Color(0xFFCC79A7);
  static const colorBlindOverTarget = Color(0xFFD55E00);
}

/// A widget that displays a custom performance overlay showing frame timing
/// stats (UI build, raster, and total) based on [FrameTiming].
///
/// Unlike Flutter's native [PerformanceOverlay], this works across all
/// platforms including web and desktop, and surfaces the metrics recommended
/// by the Flutter performance docs: delivered FPS, average, 90th/99th
/// percentile, and the number of janky frames per metric.
///
/// Per the Flutter docs, UI build and raster each get the full frame budget
/// (`1s / refreshRate`) because they pipeline across frames: while the UI
/// thread builds frame N+1, the raster thread renders frame N. A thread
/// exceeding the full target is jank in that graph; the "8ms + 8ms" split in
/// the docs is about input-to-display latency, not jank.
///
/// Each bar represents a recent frame. Bars whose duration exceeds the
/// resolved target are drawn in [overTargetColor]; bars that would exceed
/// [barRangeMax] get a small "off-chart" notch.
class ISpectPerformanceOverlay extends StatefulWidget {
  /// Creates a performance overlay widget.
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
  })  : assert(severeJankFactor >= 1.0, 'severeJankFactor must be >= 1'),
        assert(sampleSize > 0, 'sampleSize must be > 0'),
        assert(
          barRangeMax > Duration.zero,
          'barRangeMax must be greater than zero',
        );

  /// Whether the overlay is visible.
  final bool enabled;

  /// Where to align the overlay within the screen.
  ///
  /// Horizontal alignment only takes effect when [width] is finite; otherwise
  /// the overlay fills the available width.
  final Alignment alignment;

  /// How much to scale the overlay.
  final double scale;

  /// Fixed overlay width. When `null`, the overlay expands to fill the
  /// available horizontal space.
  final double? width;

  /// Overlay height. When `null`, a layout-appropriate default is used based
  /// on [compact] and [showP90].
  final double? height;

  /// Number of recent frames retained for stats and rendering.
  final int sampleSize;

  /// Target total frame time. When `null` the overlay derives it from the
  /// active display's refresh rate (`1s / refreshRate`). The same target is
  /// applied to all three metrics — the UI build and raster threads each get
  /// the full frame budget because they pipeline across frames.
  final Duration? targetFrameTime;

  /// Maximum bar duration; durations beyond this are capped and marked.
  final Duration barRangeMax;

  /// Background color of the chart container.
  final Color backgroundColor;

  /// Foreground color for the text labels, target line, and freeze button.
  final Color textColor;

  /// Bar color for UI build durations.
  final Color uiColor;

  /// Bar color for raster durations.
  final Color rasterColor;

  /// Bar color for total frame durations.
  final Color totalColor;

  /// Color applied to bars and labels that exceed the per-metric target.
  final Color overTargetColor;

  /// When `true`, renders a single-line summary instead of three charts.
  final bool compact;

  /// When `true`, displays the 90th-percentile alongside the 99th-percentile
  /// in the detailed layout. Ignored when [compact] is `true` (the compact
  /// summary stays a single line and only surfaces avg + p99).
  final bool showP90;

  /// When `true`, shows a small pause/resume button so the user can freeze
  /// the chart for inspection.
  final bool allowFreeze;

  /// Optional callback invoked for every collected [FrameTiming].
  ///
  /// Useful for shipping frame timings to a downstream collector while the
  /// overlay is visible. Keeps firing even when the chart is paused via the
  /// freeze button so the downstream pipeline does not lose data.
  ///
  /// Invoked synchronously from `SchedulerBinding.addTimingsCallback` —
  /// keep the callback fast (microseconds), or defer heavy work to a
  /// post-frame callback or isolate. Exceptions thrown from this callback
  /// are caught and logged via [ISpect.logger] so they do not poison the
  /// engine's timings dispatch.
  final void Function(FrameTiming timing)? onFrameTiming;

  /// When `true`, frames whose total duration exceeds
  /// `targetFrameTime × [severeJankFactor]` are logged to [ISpect.logger] as
  /// warnings. Defaults to `false` to avoid log spam.
  final bool enableJankLogging;

  /// Multiplier over the total target above which a frame is considered
  /// "severe jank" worth logging. Defaults to `2.0` — frames that visibly
  /// hitch on a 60Hz display.
  final double severeJankFactor;

  /// The widget to display behind the overlay.
  final Widget child;

  @override
  State<ISpectPerformanceOverlay> createState() =>
      _ISpectPerformanceOverlayState();
}

class _ISpectPerformanceOverlayState extends State<ISpectPerformanceOverlay> {
  bool _paused = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final target = widget.targetFrameTime ?? _resolveTargetFromDisplay(context);
    final refreshRate = _resolveRefreshRate(context);
    final resolvedHeight = widget.height ?? _defaultHeight();

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Align(
            alignment: widget.alignment,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: RepaintBoundary(
                child: Transform.scale(
                  alignment: widget.alignment,
                  scale: widget.scale,
                  child: SizedBox(
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
                    ),
                  ),
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
    if (widget.compact) return 24;
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

/// Internal stateful widget that collects frame timings and lays out the
/// header, charts, and the freeze button.
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

  @override
  State<_OverlayBody> createState() => _OverlayBodyState();
}

class _OverlayBodyState extends State<_OverlayBody> {
  List<FrameTiming> _samples = const [];
  final List<FrameTiming> _pendingSamples = [];

  bool _skippedFirstSample = false;
  bool _pendingSetState = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timingsCallback);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_timingsCallback);
    super.dispose();
  }

  /// Skips the first reported frame to avoid warm-up noise, fans the timings
  /// out to side-effect consumers ([widget.onFrameTiming], jank logging), and
  /// accumulates the batch for visualization unless the chart is frozen.
  ///
  /// Pause only freezes the visual update path: the downstream observer
  /// callback and jank logging keep flowing so the user can pause the chart
  /// to inspect a spike without dropping data on the floor.
  void _timingsCallback(List<FrameTiming> frameTimings) {
    if (!mounted) return;

    final newSamples = _skippedFirstSample
        ? frameTimings
        : frameTimings.length > 1
            ? frameTimings.sublist(1)
            : const <FrameTiming>[];
    _skippedFirstSample = true;

    if (newSamples.isEmpty) return;

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

    if (widget.paused) return;

    _pendingSamples.addAll(newSamples);

    if (_pendingSetState) return;
    _pendingSetState = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _pendingSetState = false;
        return;
      }
      final combined = <FrameTiming>[..._samples, ..._pendingSamples];
      final dropCount = combined.length - widget.sampleSize;
      setState(() {
        _samples = dropCount > 0 ? combined.sublist(dropCount) : combined;
        _pendingSamples.clear();
        _pendingSetState = false;
      });
    });
  }

  void _logSevereJank(Iterable<FrameTiming> samples) {
    final thresholdUs =
        (widget.target.inMicroseconds * widget.severeJankFactor).round();
    final threshold = Duration(microseconds: thresholdUs);
    for (final t in samples) {
      if (t.totalSpan <= threshold) continue;
      ISpect.logger.warning(
        'Performance jank: total ${_formatMs(t.totalSpan)}ms '
        '(UI ${_formatMs(t.buildDuration)}ms · '
        'raster ${_formatMs(t.rasterDuration)}ms · '
        'target ${_formatMs(widget.target)}ms)',
      );
    }
  }

  double? _computeDeliveredFps() => computeDeliveredFpsFromVsyncs(
        <int>[
          for (final t in _samples) t.timestampInMicroseconds(FramePhase.vsyncStart),
        ],
        widget.refreshRate,
      );

  @override
  Widget build(BuildContext context) {
    final uiSamples = <Duration>[for (final e in _samples) e.buildDuration];
    final rasterSamples = <Duration>[
      for (final e in _samples) e.rasterDuration,
    ];
    final totalSamples = <Duration>[for (final e in _samples) e.totalSpan];

    final fps = _computeDeliveredFps();
    final target = widget.target;

    return DefaultTextStyle(
      style: TextStyle(
        color: widget.textColor,
        fontSize: _kStatsFontSize,
        height: _kStatsLineHeight,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      child: ColoredBox(
        color: widget.backgroundColor,
        child: ClipRect(
          child: Stack(
            children: [
              IgnorePointer(
                child: widget.compact
                    ? _CompactBody(
                        uiSamples: uiSamples,
                        rasterSamples: rasterSamples,
                        totalSamples: totalSamples,
                        uiTarget: target,
                        rasterTarget: target,
                        totalTarget: target,
                        refreshRate: widget.refreshRate,
                        fps: fps,
                        textColor: widget.textColor,
                        uiColor: widget.uiColor,
                        rasterColor: widget.rasterColor,
                        totalColor: widget.totalColor,
                        overTargetColor: widget.overTargetColor,
                        paused: widget.paused,
                      )
                    : _DetailedBody(
                        uiSamples: uiSamples,
                        rasterSamples: rasterSamples,
                        totalSamples: totalSamples,
                        sampleSize: widget.sampleSize,
                        uiTarget: target,
                        rasterTarget: target,
                        totalTarget: target,
                        barRangeMax: widget.barRangeMax,
                        refreshRate: widget.refreshRate,
                        fps: fps,
                        textColor: widget.textColor,
                        uiColor: widget.uiColor,
                        rasterColor: widget.rasterColor,
                        totalColor: widget.totalColor,
                        overTargetColor: widget.overTargetColor,
                        showP90: widget.showP90,
                        paused: widget.paused,
                      ),
              ),
              if (widget.allowFreeze)
                Positioned(
                  top: 1,
                  right: 1,
                  child: _FreezeButton(
                    paused: widget.paused,
                    onTap: widget.onTogglePause,
                    color: widget.textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailedBody extends StatelessWidget {
  const _DetailedBody({
    required this.uiSamples,
    required this.rasterSamples,
    required this.totalSamples,
    required this.sampleSize,
    required this.uiTarget,
    required this.rasterTarget,
    required this.totalTarget,
    required this.barRangeMax,
    required this.refreshRate,
    required this.fps,
    required this.textColor,
    required this.uiColor,
    required this.rasterColor,
    required this.totalColor,
    required this.overTargetColor,
    required this.showP90,
    required this.paused,
  });

  final List<Duration> uiSamples;
  final List<Duration> rasterSamples;
  final List<Duration> totalSamples;
  final int sampleSize;
  final Duration uiTarget;
  final Duration rasterTarget;
  final Duration totalTarget;
  final Duration barRangeMax;
  final double refreshRate;
  final double? fps;
  final Color textColor;
  final Color uiColor;
  final Color rasterColor;
  final Color totalColor;
  final Color overTargetColor;
  final bool showP90;
  final bool paused;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(
            refreshRate: refreshRate,
            fps: fps,
            textColor: textColor,
            paused: paused,
          ),
          Expanded(
            child: Row(
              children: [
                _ChartColumn(
                  type: 'UI',
                  samples: uiSamples,
                  color: uiColor,
                  sampleSize: sampleSize,
                  target: uiTarget,
                  barRangeMax: barRangeMax,
                  textColor: textColor,
                  overTargetColor: overTargetColor,
                  showP90: showP90,
                ),
                _Divider(color: textColor),
                _ChartColumn(
                  type: 'Raster',
                  samples: rasterSamples,
                  color: rasterColor,
                  sampleSize: sampleSize,
                  target: rasterTarget,
                  barRangeMax: barRangeMax,
                  textColor: textColor,
                  overTargetColor: overTargetColor,
                  showP90: showP90,
                ),
                _Divider(color: textColor),
                _ChartColumn(
                  type: 'Total',
                  samples: totalSamples,
                  color: totalColor,
                  sampleSize: sampleSize,
                  target: totalTarget,
                  barRangeMax: barRangeMax,
                  textColor: textColor,
                  overTargetColor: overTargetColor,
                  showP90: showP90,
                ),
              ],
            ),
          ),
        ],
      );
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({
    required this.uiSamples,
    required this.rasterSamples,
    required this.totalSamples,
    required this.uiTarget,
    required this.rasterTarget,
    required this.totalTarget,
    required this.refreshRate,
    required this.fps,
    required this.textColor,
    required this.uiColor,
    required this.rasterColor,
    required this.totalColor,
    required this.overTargetColor,
    required this.paused,
  });

  final List<Duration> uiSamples;
  final List<Duration> rasterSamples;
  final List<Duration> totalSamples;
  final Duration uiTarget;
  final Duration rasterTarget;
  final Duration totalTarget;
  final double refreshRate;
  final double? fps;
  final Color textColor;
  final Color uiColor;
  final Color rasterColor;
  final Color totalColor;
  final Color overTargetColor;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final ui = PerformanceChartStats.from(uiSamples, uiTarget);
    final raster = PerformanceChartStats.from(rasterSamples, rasterTarget);
    final total = PerformanceChartStats.from(totalSamples, totalTarget);

    TextSpan metric({
      required String label,
      required Color color,
      required PerformanceChartStats stats,
      required Duration target,
    }) =>
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: ' ${_formatMs(stats.avg)}/${_formatMs(stats.p99)}ms ',
              style:
                  stats.p99 > target ? TextStyle(color: overTargetColor) : null,
            ),
            const TextSpan(text: '· '),
          ],
        );

    // Use the Total chart's jank count as the user-visible "frames missed"
    // figure — a single janky frame typically trips multiple per-thread
    // counters, and summing them would triple-count the same dropped frame.
    final jankTotal = total.jankCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${refreshRate.toStringAsFixed(0)}Hz · '
                    '${fps?.toStringAsFixed(1) ?? '--'} FPS · ',
              ),
              metric(label: 'UI', color: uiColor, stats: ui, target: uiTarget),
              metric(
                label: 'R',
                color: rasterColor,
                stats: raster,
                target: rasterTarget,
              ),
              metric(
                label: 'T',
                color: totalColor,
                stats: total,
                target: totalTarget,
              ),
              TextSpan(
                text: '$jankTotal jank',
                style: jankTotal > 0 ? TextStyle(color: overTargetColor) : null,
              ),
              if (paused)
                TextSpan(
                  text: '  · PAUSED',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.refreshRate,
    required this.fps,
    required this.textColor,
    required this.paused,
  });

  final double refreshRate;
  final double? fps;
  final Color textColor;
  final bool paused;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _kHeaderHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.85),
                  fontSize: _kHeaderFontSize,
                ),
                children: [
                  TextSpan(text: '${refreshRate.toStringAsFixed(0)}Hz · '),
                  TextSpan(
                    text: '${fps?.toStringAsFixed(1) ?? '--'} FPS',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (paused)
                    TextSpan(
                      text: '  · PAUSED',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 1,
        child: ColoredBox(color: color.withValues(alpha: 0.2)),
      );
}

class _ChartColumn extends StatelessWidget {
  const _ChartColumn({
    required this.type,
    required this.samples,
    required this.color,
    required this.sampleSize,
    required this.target,
    required this.barRangeMax,
    required this.textColor,
    required this.overTargetColor,
    required this.showP90,
  });

  final String type;
  final List<Duration> samples;
  final Color color;
  final int sampleSize;
  final Duration target;
  final Duration barRangeMax;
  final Color textColor;
  final Color overTargetColor;
  final bool showP90;

  @override
  Widget build(BuildContext context) => Expanded(
        child: RepaintBoundary(
          child: _PerformanceChart(
            type: type,
            samples: samples,
            sampleSize: sampleSize,
            target: target,
            barRangeMax: barRangeMax,
            color: color,
            textColor: textColor,
            overTargetColor: overTargetColor,
            showP90: showP90,
          ),
        ),
      );
}

/// A chart that renders frame timings as vertical bars plus a stats overlay.
class _PerformanceChart extends StatelessWidget {
  const _PerformanceChart({
    required this.type,
    required this.samples,
    required this.sampleSize,
    required this.target,
    required this.barRangeMax,
    required this.color,
    required this.textColor,
    required this.overTargetColor,
    required this.showP90,
  }) : assert(samples.length <= sampleSize, 'samples must fit sampleSize');

  final String type;
  final List<Duration> samples;
  final int sampleSize;
  final Duration target;
  final Duration barRangeMax;
  final Color color;
  final Color textColor;
  final Color overTargetColor;
  final bool showP90;

  @override
  Widget build(BuildContext context) {
    final stats = PerformanceChartStats.from(samples, target);

    final spans = <TextSpan>[
      TextSpan(
        text: type,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      TextSpan(
        text: '  ${stats.jankCount} jank\n',
        style: stats.jankCount > 0 ? TextStyle(color: overTargetColor) : null,
      ),
      TextSpan(
        text: 'avg ${_formatMs(stats.avg)}ms\n',
        style: stats.avg > target ? TextStyle(color: overTargetColor) : null,
      ),
      if (showP90)
        TextSpan(
          text: 'p90 ${_formatMs(stats.p90)}ms\n',
          style: stats.p90 > target ? TextStyle(color: overTargetColor) : null,
        ),
      TextSpan(
        text: 'p99 ${_formatMs(stats.p99)}ms',
        style: stats.p99 > target ? TextStyle(color: overTargetColor) : null,
      ),
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _OverlayPainter(
              samples: samples,
              sampleSize: sampleSize,
              target: target,
              barRangeMax: barRangeMax,
              color: color,
              overTargetColor: overTargetColor,
              gridColor: textColor.withValues(alpha: 0.4),
              capMarkerColor: textColor.withValues(alpha: 0.85),
            ),
          ),
        ),
        Positioned(
          left: 4,
          right: 4,
          top: 2,
          child: Text.rich(TextSpan(children: spans)),
        ),
      ],
    );
  }
}

/// Custom painter that draws the per-frame bars, a per-metric target line,
/// multiples of the target as faint reference lines, and a small marker on
/// bars whose duration exceeded [barRangeMax].
class _OverlayPainter extends CustomPainter {
  const _OverlayPainter({
    required this.samples,
    required this.sampleSize,
    required this.target,
    required this.barRangeMax,
    required this.color,
    required this.overTargetColor,
    required this.gridColor,
    required this.capMarkerColor,
  });

  final List<Duration> samples;
  final int sampleSize;
  final Duration target;
  final Duration barRangeMax;
  final Color color;
  final Color overTargetColor;
  final Color gridColor;
  final Color capMarkerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rangeUs = barRangeMax.inMicroseconds;
    if (rangeUs <= 0) return;

    if (samples.isNotEmpty && sampleSize > 0) {
      final slotWidth = size.width / sampleSize;
      final barWidth = (slotWidth - _kBarGap).clamp(1.0, slotWidth);
      final paint = Paint();

      for (var i = sampleSize - 1; i >= 0; i--) {
        final index = i - sampleSize + samples.length;
        if (index < 0) break;
        final duration = samples[index];
        final isCapped = duration.inMicroseconds > rangeUs;
        final heightFactor =
            (duration.inMicroseconds / rangeUs).clamp(0.0, 1.0);
        paint.color = duration <= target ? color : overTargetColor;
        final left = i * slotWidth;
        canvas.drawRect(
          Rect.fromLTWH(
            left,
            size.height * (1 - heightFactor),
            barWidth,
            size.height * heightFactor,
          ),
          paint,
        );

        if (isCapped) {
          final centerX = left + barWidth / 2;
          final path = Path()
            ..moveTo(centerX, 0)
            ..lineTo(centerX - barWidth / 2, 4)
            ..lineTo(centerX + barWidth / 2, 4)
            ..close();
          canvas.drawPath(path, Paint()..color = capMarkerColor);
        }
      }
    }

    // Grid lines are drawn last so the per-metric target (1×) and its
    // multiples stay visible even when bars exceed them — mirroring how
    // Flutter's native performance overlay keeps the 16ms reference lines on
    // top of the graph.
    final linePaint = Paint()..strokeWidth = 1;
    for (var multiple = 1; multiple <= 4; multiple++) {
      final yUs = target.inMicroseconds * multiple;
      if (yUs > rangeUs) break;
      final factor = yUs / rangeUs;
      final y = size.height * (1 - factor);
      linePaint.color = multiple == 1
          ? gridColor
          : gridColor.withValues(alpha: gridColor.a * 0.4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) =>
      !identical(oldDelegate.samples, samples) ||
      oldDelegate.target != target ||
      oldDelegate.barRangeMax != barRangeMax ||
      oldDelegate.color != color ||
      oldDelegate.overTargetColor != overTargetColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.capMarkerColor != capMarkerColor;
}

/// Small interactive button that toggles between the recording and frozen
/// states of the overlay.
///
/// Sits as a sibling of the `IgnorePointer`-wrapped chart body inside the
/// overlay stack, so taps anywhere except this button fall through to the
/// app behind the overlay.
class _FreezeButton extends StatelessWidget {
  const _FreezeButton({
    required this.paused,
    required this.onTap,
    required this.color,
  });

  final bool paused;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label:
            paused ? 'Resume performance overlay' : 'Pause performance overlay',
        child: SizedBox(
          width: _kPauseButtonSize,
          height: _kPauseButtonSize,
          child: Material(
            type: MaterialType.transparency,
            child: InkResponse(
              onTap: onTap,
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
