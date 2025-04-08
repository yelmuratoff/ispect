import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget that displays a custom performance overlay showing frame timing stats
/// (UI, Raster, and High Latency) based on `FrameTiming`.
///
/// Unlike Flutter's native `PerformanceOverlay`, this works across all platforms
/// including web and desktop, and provides more granular, opinionated visual feedback.
///
/// The overlay displays charts for:
/// - UI frame build durations
/// - Raster durations
/// - Total frame latencies
///
/// Each bar represents a recent frame, with red bars indicating frame times
/// that exceed the `targetFrameTime`.
///
/// Can be aligned and scaled, and provides customizable styling options.
class CustomPerformanceOverlay extends StatelessWidget {
  /// Creates a performance overlay widget.
  ///
  /// The `child` is the main content; the overlay renders on top of it when [enabled].
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
                  child: Transform.scale(
                    alignment: alignment,
                    scale: scale,
                    child: _CustomPerformanceOverlay(
                      sampleSize: sampleSize,
                      targetFrameTime: targetFrameTime,
                      barRangeMax: barRangeMax,
                      backgroundColor: backgroundColor,
                      textColor: textColor,
                      textBackgroundColor: textBackgroundColor,
                      uiColor: uiColor,
                      rasterColor: rasterColor,
                      highLatencyColor: highLatencyColor,
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
  const _CustomPerformanceOverlay({
    required this.sampleSize,
    required this.targetFrameTime,
    required this.barRangeMax,
    required this.backgroundColor,
    required this.textColor,
    required this.textBackgroundColor,
    required this.uiColor,
    required this.rasterColor,
    required this.highLatencyColor,
  });

  final int sampleSize;
  final Duration targetFrameTime;
  final Duration barRangeMax;
  final Color backgroundColor;
  final Color textColor;
  final Color textBackgroundColor;
  final Color uiColor;
  final Color rasterColor;
  final Color highLatencyColor;

  @override
  State<_CustomPerformanceOverlay> createState() =>
      _CustomPerformanceOverlayState();
}

class _CustomPerformanceOverlayState extends State<_CustomPerformanceOverlay> {
  List<FrameTiming> _samples = [];
  bool _skippedFirstSample = false;

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
  /// This is invoked by `SchedulerBinding.addTimingsCallback` whenever new frame
  /// timings are available. It stores a rolling window of the most recent
  /// `widget.sampleSize` entries.
  void _timingsCallback(List<FrameTiming> frameTimings) {
    // Prevent updating state if widget is already disposed.
    if (!mounted) return;

    // Skip the very first frame sample to avoid warm-up noise.
    final newSamples =
        _skippedFirstSample ? frameTimings : frameTimings.sublist(1);
    _skippedFirstSample = true;

    // Merge existing and new samples into a combined list.
    final combined = [..._samples, ...newSamples];

    // If combined exceeds sample size, calculate how many old entries to drop.
    final dropCount = math.max(0, combined.length - widget.sampleSize);

    // Defer setState until the current frame is done rendering.
    // This ensures safe rebuild and avoids context usage during build.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        // Retain only the latest `sampleSize` number of samples.
        _samples = combined.sublist(dropCount);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: widget.textColor,
      fontSize: 10,
      backgroundColor: widget.textBackgroundColor,
    );

    final mediaQuery = MediaQuery.maybeOf(context);
    final devicePixelRatio = mediaQuery?.devicePixelRatio ?? 1;

    final width = 448.0 * devicePixelRatio.clamp(1.0, 2.0);
    final height = 80.0 * devicePixelRatio.clamp(1.0, 2.0);

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: ClipRect(
          child: Row(
            children: [
              Expanded(
                child: _PerformanceChart(
                  type: 'UI',
                  samples: [for (final e in _samples) e.rasterDuration],
                  sampleSize: widget.sampleSize,
                  targetFrameTime: widget.targetFrameTime,
                  barRangeMax: widget.barRangeMax,
                  color: widget.uiColor,
                  textStyle: textStyle,
                ),
              ),
              const VerticalDivider(width: 2, thickness: 2),
              Expanded(
                child: _PerformanceChart(
                  type: 'raster',
                  samples: [for (final e in _samples) e.buildDuration],
                  sampleSize: widget.sampleSize,
                  targetFrameTime: widget.targetFrameTime,
                  barRangeMax: widget.barRangeMax,
                  color: widget.rasterColor,
                  textStyle: textStyle,
                ),
              ),
              const VerticalDivider(width: 2, thickness: 2),
              Expanded(
                child: _PerformanceChart(
                  type: 'high latency',
                  samples: [for (final e in _samples) e.totalSpan],
                  sampleSize: widget.sampleSize,
                  targetFrameTime: widget.targetFrameTime,
                  barRangeMax: widget.barRangeMax,
                  color: widget.highLatencyColor,
                  textStyle: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A chart widget that renders frame timings as vertical bars.
///
/// Displays the maximum, average, and FPS summary for each sample set.
class _PerformanceChart extends StatelessWidget {
  const _PerformanceChart({
    required this.type,
    required this.samples,
    required this.sampleSize,
    required this.targetFrameTime,
    required this.barRangeMax,
    required this.color,
    required this.textStyle,
  }) : assert(samples.length <= sampleSize);

  final String type;
  final List<Duration> samples;
  final int sampleSize;
  final Duration targetFrameTime;
  final Duration barRangeMax;
  final Color color;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    var maxDuration = Duration.zero;
    var total = Duration.zero;

    for (final sample in samples) {
      if (sample > maxDuration) maxDuration = sample;
      total += sample;
    }

    final avg = samples.isEmpty
        ? Duration.zero
        : Duration(microseconds: total.inMicroseconds ~/ samples.length);
    final fps = samples.isEmpty ? 0 : 1e6 / avg.inMicroseconds;

    return Stack(
      children: [
        SizedBox.expand(
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
///   - Bars under the target duration are colored with `color`.
///   - Bars exceeding the target are colored red.
///
/// Used in performance overlays to provide visual feedback on frame rendering
/// times, particularly useful in diagnosing dropped frames or jank.
class _OverlayPainter extends CustomPainter {
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

  /// Color for bars that are within or below `targetFrameTime`.
  ///
  /// Frames exceeding the target will be rendered in red.
  final Color color;

  /// Paints the performance overlay chart with frame duration bars.
  ///
  /// This method visualizes:
  /// - A horizontal line at the target frame duration to indicate the performance threshold.
  /// - A sequence of vertical bars for each frame timing sample:
  ///   - Bars are scaled relative to `barRangeMax`.
  ///   - Bars with duration above `targetFrameTime` are colored red.
  ///   - Bars below or equal to `targetFrameTime` use the configured [color].
  ///
  /// Parameters:
  /// - `canvas`: The canvas to draw onto.
  /// - `size`: The size of the available drawing area.
  ///
  /// Example visualization behavior:
  /// - If `targetFrameTime` is 16ms, and a bar represents 24ms, it will be colored red and capped
  ///   to full chart height if it exceeds `barRangeMax`.
  ///
  /// Edge cases:
  /// - If there are fewer samples than `sampleSize`, only the available samples are drawn.
  /// - Samples are rendered from oldest (left) to newest (right).
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

/// Extension on `Duration` to provide convenience methods for
/// division and formatted millisecond representation.
///
/// Useful for performance monitoring and frame timing calculations.
extension on Duration {
  /// Divides this `Duration` by another [Duration] and returns the result as a [double].
  ///
  /// For example:
  /// ```dart
  /// const a = Duration(milliseconds: 24);
  /// const b = Duration(milliseconds: 12);
  /// final ratio = a / b; // 2.0
  /// ```
  ///
  /// Edge cases:
  /// - Returns `infinity` if `other` is zero.
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
