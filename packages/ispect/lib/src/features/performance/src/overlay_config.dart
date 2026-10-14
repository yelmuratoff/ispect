import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

@internal
@immutable
final class PerformanceOverlayConfig {
  const PerformanceOverlayConfig({
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
    required this.enableJankLogging,
    required this.severeJankFactor,
    required this.jankLogCooldown,
    required this.showMemory,
    required this.memoryWarnRatio,
    required this.memoryDangerRatio,
    required this.showAllTimeStats,
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
  final bool enableJankLogging;
  final double severeJankFactor;
  final Duration jankLogCooldown;
  final bool showMemory;
  final double memoryWarnRatio;
  final double memoryDangerRatio;
  final bool showAllTimeStats;
  final int jankBurstWindow;
  final Duration jankBurstCooldown;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceOverlayConfig &&
          other.sampleSize == sampleSize &&
          other.target == target &&
          other.refreshRate == refreshRate &&
          other.barRangeMax == barRangeMax &&
          other.backgroundColor == backgroundColor &&
          other.textColor == textColor &&
          other.uiColor == uiColor &&
          other.rasterColor == rasterColor &&
          other.totalColor == totalColor &&
          other.overTargetColor == overTargetColor &&
          other.compact == compact &&
          other.showP90 == showP90 &&
          other.allowFreeze == allowFreeze &&
          other.enableJankLogging == enableJankLogging &&
          other.severeJankFactor == severeJankFactor &&
          other.jankLogCooldown == jankLogCooldown &&
          other.showMemory == showMemory &&
          other.memoryWarnRatio == memoryWarnRatio &&
          other.memoryDangerRatio == memoryDangerRatio &&
          other.showAllTimeStats == showAllTimeStats &&
          other.jankBurstWindow == jankBurstWindow &&
          other.jankBurstCooldown == jankBurstCooldown;

  @override
  int get hashCode => Object.hashAll([
    sampleSize,
    target,
    refreshRate,
    barRangeMax,
    backgroundColor,
    textColor,
    uiColor,
    rasterColor,
    totalColor,
    overTargetColor,
    compact,
    showP90,
    allowFreeze,
    enableJankLogging,
    severeJankFactor,
    jankLogCooldown,
    showMemory,
    memoryWarnRatio,
    memoryDangerRatio,
    showAllTimeStats,
    jankBurstWindow,
    jankBurstCooldown,
  ]);
}
