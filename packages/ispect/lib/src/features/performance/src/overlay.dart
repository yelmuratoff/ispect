import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget that displays a custom performance overlay showing frame timing stats
/// (UI, Raster, and High Latency) based on [FrameTiming].
///
/// Unlike Flutter's native [PerformanceOverlay], this works across all platforms
/// including web, and provides more granular, opinionated visual feedback.
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

  /// Collects new [FrameTiming] samples and updates the widget state.
  ///
  /// This method is used as a callback for [SchedulerBinding.addTimingsCallback]
  /// to gather frame performance metrics.
  ///
  /// Behavior:
  /// - Skips the very first sample received after initialization to avoid
  ///   potentially invalid or noisy data.
  /// - Merges the incoming [frameTimings] with the existing [_samples].
  /// - Ensures the sample list length does not exceed [widget.sampleSize].
  /// - Schedules a post-frame update to safely call [setState] after the frame.
  ///
  /// Guards:
  /// - Skips processing entirely if the widget is not [mounted].
  /// - Also checks [mounted] inside the post-frame callback to avoid
  ///   updating state on a disposed widget.
  ///
  /// Parameters:
  /// - [frameTimings]: A list of recent [FrameTiming] data from the engine.
  ///
  /// Edge cases:
  /// - The first batch of frame timings will have its first sample ignored,
  ///   ensuring cleaner data collection.
  /// - If the combined list of samples exceeds [widget.sampleSize],
  ///   older entries are dropped from the front.
  ///
  /// Example usage:
  /// ```dart
  /// SchedulerBinding.instance.addTimingsCallback(_timingsCallback);
  /// ```
  void _timingsCallback(List<FrameTiming> frameTimings) {
    if (!mounted) return;

    final newSamples =
        _skippedFirstSample ? frameTimings : frameTimings.sublist(1);
    _skippedFirstSample = true;

    final combined = [..._samples, ...newSamples];
    final dropCount = math.max(0, combined.length - widget.sampleSize);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
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

    return SizedBox(
      width: 448,
      height: 64,
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
///   - Bars under the target duration are colored with [color].
///   - Bars exceeding the target are colored red.
///
/// Used in performance overlays to provide visual feedback on frame rendering
/// times, particularly useful in diagnosing dropped frames or jank.
class _OverlayPainter extends CustomPainter {
  /// Creates an instance of [_OverlayPainter].
  ///
  /// - [samples] is the list of frame render durations to visualize.
  /// - [sampleSize] controls the number of bars (samples) shown on screen.
  /// - [targetFrameTime] is the ideal frame time (e.g., 16ms for 60 FPS),
  ///   used to determine the success threshold.
  /// - [barRangeMax] is the maximum duration used for bar scaling.
  /// - [color] is the color used for bars that are under the target frame time.
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
      Offset.zero.translate(0, lineY),
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

/// Extension to add convenience methods to [Duration].
extension on Duration {
  /// Divide two durations and return a double.
  double operator /(Duration other) => inMicroseconds / other.inMicroseconds;

  /// Convert to milliseconds with 1 decimal place.
  String get ms => (inMicroseconds / 1e3).toStringAsFixed(1);
}
