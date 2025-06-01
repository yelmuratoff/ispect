import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget that displays a custom performance overlay showing frame timing stats
/// (UI, Raster, and High Latency) based on [FrameTiming].
///
/// Unlike Flutter's native [PerformanceOverlay], this works across all platforms
/// including web and desktop, and provides more granular, opinionated visual feedback.
///
/// The overlay displays charts for:
/// - UI frame build durations
/// - Raster durations
/// - Total frame latencies
///
/// Each bar represents a recent frame, with red bars indicating frame times
/// that exceed the [targetFrameTime].
///
/// Can be aligned and scaled, and provides customizable styling options.
class CustomPerformanceOverlay extends StatelessWidget {
  /// Creates a performance overlay widget.
  ///
  /// The [child] is the main content; the overlay renders on top of it when [enabled].
  const CustomPerformanceOverlay({
    required this.child,
    super.key,
    this.enabled = true,
    this.alignment = Alignment.topRight,
    this.scale = 1,
    this.sampleSize = 32,
    this.targetFrameTime = const Duration(milliseconds: 16),
    this.barRangeMax = const Duration(milliseconds: 24),
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.textBackgroundColor = const Color(0x77ffffff),
    this.uiColor = Colors.teal,
    this.rasterColor = Colors.blue,
    this.highLatencyColor = Colors.cyan,
  });

  /// Whether the overlay is visible.
  final bool enabled;

  /// Where to align the overlay within the screen.
  final Alignment alignment;

  /// How much to scale the overlay.
  final double scale;

  /// Number of recent frames to display in the chart.
  final int sampleSize;

  /// Target frame time; durations above this will be shown in red.
  final Duration targetFrameTime;

  /// Maximum expected bar duration range; durations beyond this are capped.
  final Duration barRangeMax;

  /// Background color of the chart container.
  final Color backgroundColor;

  /// Foreground color for the text labels.
  final Color textColor;

  /// Background color behind the text.
  final Color textBackgroundColor;

  /// Bar color for UI durations.
  final Color uiColor;

  /// Bar color for raster durations.
  final Color rasterColor;

  /// Bar color for total latency durations.
  final Color highLatencyColor;

  /// The widget to display behind the overlay.
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          if (enabled)
            Positioned.fill(
              child: Align(
                alignment: alignment,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: IgnorePointer(
                    child: Transform.scale(
                      alignment: alignment,
                      scale: scale,
                      child: _CustomPerformanceOverlay(
                        sampleSize: sampleSize,
                        targetFrameTime: targetFrameTime,
                        barRangeMax: barRangeMax,
                        backgroundColor: backgroundColor,
                        textColor: textColor,
                        uiColor: uiColor,
                        rasterColor: rasterColor,
                        highLatencyColor: highLatencyColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
}

/// Internal stateful widget that collects and displays frame timings.
class _CustomPerformanceOverlay extends StatefulWidget {
  /// Creates the internal performance overlay.
  const _CustomPerformanceOverlay({
    required this.sampleSize,
    required this.targetFrameTime,
    required this.barRangeMax,
    required this.backgroundColor,
    required this.textColor,
    required this.uiColor,
    required this.rasterColor,
    required this.highLatencyColor,
  });

  /// Number of recent frames to display in the chart.
  final int sampleSize;

  /// Target frame time; durations above this will be shown in red.
  final Duration targetFrameTime;

  /// Maximum expected bar duration range; durations beyond this are capped.
  final Duration barRangeMax;

  /// Background color of the chart container.
  final Color backgroundColor;

  /// Foreground color for the text labels.
  final Color textColor;

  /// Bar color for UI durations.
  final Color uiColor;

  /// Bar color for raster durations.
  final Color rasterColor;

  /// Bar color for total latency durations.
  final Color highLatencyColor;

  @override
  State<_CustomPerformanceOverlay> createState() =>
      _CustomPerformanceOverlayState();
}

/// State for [_CustomPerformanceOverlay] that manages frame timing samples.
class _CustomPerformanceOverlayState extends State<_CustomPerformanceOverlay> {
  /// Recent frame timing samples.
  List<FrameTiming> _samples = const [];

  /// Whether the first sample has been skipped (to avoid warm-up noise).
  bool _skippedFirstSample = false;

  /// Prevents multiple setState calls in one frame.
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

  /// Callback that collects frame timing samples from the engine.
  ///
  /// This is invoked by [SchedulerBinding.addTimingsCallback] whenever new frame
  /// timings are available. It stores a rolling window of the most recent
  /// [widget.sampleSize] entries.
  void _timingsCallback(List<FrameTiming> frameTimings) {
    if (!mounted) return;

    // Skip the very first frame sample to avoid warm-up noise.
    final newSamples = _skippedFirstSample
        ? frameTimings
        : frameTimings.length > 1
            ? frameTimings.sublist(1)
            : const <FrameTiming>[];
    _skippedFirstSample = true;

    if (newSamples.isEmpty) return;

    final combined = <FrameTiming>[
      ..._samples,
      ...newSamples,
    ];
    final dropCount = math.max(0, combined.length - widget.sampleSize);
    final updated = combined.sublist(dropCount);

    // Prevent multiple setState calls in one frame.
    if (_pendingSetState) return;
    _pendingSetState = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _samples = updated;
        _pendingSetState = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio =
        MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final width = 448.0 * devicePixelRatio.clamp(1.0, 2.0);
    final height = 40.0 * devicePixelRatio.clamp(1.0, 2.0);

    // DRY: constant for text style
    const textStyle = TextStyle(fontSize: 10);

    // Optimization: buildDuration/rasterDuration/totalSpan are computed once
    final uiSamples = [for (final e in _samples) e.buildDuration];
    final rasterSamples = [for (final e in _samples) e.rasterDuration];
    final latencySamples = [for (final e in _samples) e.totalSpan];

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: ClipRect(
          child: Row(
            children: [
              _ChartColumn(
                type: 'UI',
                samples: uiSamples,
                color: widget.uiColor,
                sampleSize: widget.sampleSize,
                targetFrameTime: widget.targetFrameTime,
                barRangeMax: widget.barRangeMax,
                textStyle: textStyle,
              ),
              const VerticalDivider(width: 2, thickness: 2),
              _ChartColumn(
                type: 'raster',
                samples: rasterSamples,
                color: widget.rasterColor,
                sampleSize: widget.sampleSize,
                targetFrameTime: widget.targetFrameTime,
                barRangeMax: widget.barRangeMax,
                textStyle: textStyle,
              ),
              const VerticalDivider(width: 2, thickness: 2),
              _ChartColumn(
                type: 'high latency',
                samples: latencySamples,
                color: widget.highLatencyColor,
                sampleSize: widget.sampleSize,
                targetFrameTime: widget.targetFrameTime,
                barRangeMax: widget.barRangeMax,
                textStyle: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A column widget that displays a single performance chart.
class _ChartColumn extends StatelessWidget {
  /// Creates a chart column for a specific frame timing type.
  const _ChartColumn({
    required this.type,
    required this.samples,
    required this.color,
    required this.sampleSize,
    required this.targetFrameTime,
    required this.barRangeMax,
    required this.textStyle,
  });

  /// The type of frame timing (e.g., 'UI', 'raster', 'high latency').
  final String type;

  /// The list of frame timing samples to display.
  final List<Duration> samples;

  /// The color of the bars in the chart.
  final Color color;

  /// Number of recent frames to display in the chart.
  final int sampleSize;

  /// Target frame time; durations above this will be shown in red.
  final Duration targetFrameTime;

  /// Maximum expected bar duration range; durations beyond this are capped.
  final Duration barRangeMax;

  /// Text style for the chart labels.
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) => Expanded(
        child: _PerformanceChart(
          type: type,
          samples: samples,
          sampleSize: sampleSize,
          targetFrameTime: targetFrameTime,
          barRangeMax: barRangeMax,
          color: color,
          textStyle: textStyle,
        ),
      );
}

/// A chart widget that renders frame timings as vertical bars.
///
/// Displays the maximum, average, and FPS summary for each sample set.
class _PerformanceChart extends StatelessWidget {
  /// Creates a performance chart for a set of frame timings.
  const _PerformanceChart({
    required this.type,
    required this.samples,
    required this.sampleSize,
    required this.targetFrameTime,
    required this.barRangeMax,
    required this.color,
    required this.textStyle,
  }) : assert(samples.length <= sampleSize);

  /// The type of frame timing (e.g., 'UI', 'raster', 'high latency').
  final String type;

  /// The list of frame timing samples to display.
  final List<Duration> samples;

  /// Number of recent frames to display in the chart.
  final int sampleSize;

  /// Target frame time; durations above this will be shown in red.
  final Duration targetFrameTime;

  /// Maximum expected bar duration range; durations beyond this are capped.
  final Duration barRangeMax;

  /// The color of the bars in the chart.
  final Color color;

  /// Text style for the chart labels.
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final maxDuration = samples.isEmpty
        ? Duration.zero
        : samples.reduce((a, b) => a > b ? a : b);
    final total = samples.fold(Duration.zero, (a, b) => a + b);
    final avg = samples.isEmpty
        ? Duration.zero
        : Duration(microseconds: total.inMicroseconds ~/ samples.length);
    final fps = samples.isEmpty ? 0 : 1e6 / avg.inMicroseconds;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _OverlayPainter(
              samples,
              sampleSize,
              targetFrameTime,
              barRangeMax,
              color,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'max ${maxDuration.ms}ms ',
                    style: TextStyle(
                      color: maxDuration <= targetFrameTime ? null : Colors.red,
                    ),
                  ),
                  TextSpan(
                    text: 'avg ${avg.ms}ms\n',
                    style: TextStyle(
                      color: avg <= targetFrameTime ? null : Colors.red,
                    ),
                  ),
                  TextSpan(
                    text: '$type <= ${fps.toStringAsFixed(1)} FPS',
                  ),
                ],
                style: textStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A custom painter that visualizes frame performance over time.
///
/// This painter draws:
/// - A horizontal black line representing the target frame duration.
/// - A series of vertical bars (one per sampled frame duration) showing how
///   each frame compares to the target and maximum frame duration.
///   - Bars under the target duration are colored with [color].
///   - Bars exceeding the target are colored red.
///
/// Used in performance overlays to provide visual feedback on frame rendering
/// times, particularly useful in diagnosing dropped frames or jank.
class _OverlayPainter extends CustomPainter {
  /// Creates a painter for the performance overlay chart.
  const _OverlayPainter(
    this.samples,
    this.sampleSize,
    this.targetFrameTime,
    this.barRangeMax,
    this.color,
  );

  /// Frame duration samples to visualize.
  final List<Duration> samples;

  /// Number of frame samples to show in the overlay.
  final int sampleSize;

  /// Target frame duration (e.g., 16ms for 60 FPS).
  final Duration targetFrameTime;

  /// Maximum frame duration represented in the chart.
  ///
  /// Any durations above this value will be capped visually at full height.
  final Duration barRangeMax;

  /// Color for bars that are within or below [targetFrameTime].
  ///
  /// Frames exceeding the target will be rendered in red.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a horizontal line to mark the target frame time.
    final lineY = size.height * (1 - targetFrameTime / barRangeMax);
    canvas.drawLine(
      Offset(0, lineY),
      Offset(size.width, lineY),
      Paint()..color = Colors.black,
    );

    final barWidth = size.width / sampleSize;
    final paint = Paint();

    // Draw bars for each sample (most recent on the right).
    for (var i = sampleSize - 1; i >= 0; i--) {
      final index = i - sampleSize + samples.length;
      if (index < 0) break;
      final duration = samples[index];
      final heightFactor = duration / barRangeMax;
      paint.color = duration <= targetFrameTime ? color : Colors.red;
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,
          size.height * (1 - heightFactor),
          barWidth,
          size.height * heightFactor,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) =>
      oldDelegate.samples != samples;
}

/// Extension on [Duration] to provide convenience methods for
/// division and formatted millisecond representation.
///
/// Useful for performance monitoring and frame timing calculations.
extension on Duration {
  /// Divides this [Duration] by another [Duration] and returns the result as a [double].
  ///
  /// For example:
  /// ```dart
  /// const a = Duration(milliseconds: 24);
  /// const b = Duration(milliseconds: 12);
  /// final ratio = a / b; // 2.0
  /// ```
  ///
  /// Edge cases:
  /// - Returns `infinity` if [other] is zero.
  /// - Returns `NaN` if both are zero.
  double operator /(Duration other) => inMicroseconds / other.inMicroseconds;

  /// Returns this duration as milliseconds with 1 decimal precision.
  ///
  /// Example:
  /// ```dart
  /// const d = Duration(microseconds: 12345);
  /// print(d.ms); // "12.3"
  /// ```
  ///
  /// This is useful for readable frame timing overlays or logs.
  String get ms => (inMicroseconds / 1e3).toStringAsFixed(1);
}
