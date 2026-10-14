import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/performance/src/overlay_config.dart';

PerformanceOverlayConfig _config({
  int sampleSize = 64,
  Duration target = const Duration(microseconds: 16667),
  double refreshRate = 60,
  Duration barRangeMax = const Duration(milliseconds: 50),
  Color backgroundColor = Colors.white,
  Color textColor = Colors.black,
  Color uiColor = Colors.teal,
  Color rasterColor = Colors.blue,
  Color totalColor = Colors.purple,
  Color overTargetColor = Colors.red,
  bool compact = false,
  bool showP90 = false,
  bool allowFreeze = true,
  bool enableJankLogging = false,
  double severeJankFactor = 2,
  Duration jankLogCooldown = const Duration(seconds: 1),
  bool showMemory = true,
  double memoryWarnRatio = 1.3,
  double memoryDangerRatio = 2,
  bool showAllTimeStats = false,
  int jankBurstWindow = 3,
  Duration jankBurstCooldown = const Duration(seconds: 1),
}) => PerformanceOverlayConfig(
  sampleSize: sampleSize,
  target: target,
  refreshRate: refreshRate,
  barRangeMax: barRangeMax,
  backgroundColor: backgroundColor,
  textColor: textColor,
  uiColor: uiColor,
  rasterColor: rasterColor,
  totalColor: totalColor,
  overTargetColor: overTargetColor,
  compact: compact,
  showP90: showP90,
  allowFreeze: allowFreeze,
  enableJankLogging: enableJankLogging,
  severeJankFactor: severeJankFactor,
  jankLogCooldown: jankLogCooldown,
  showMemory: showMemory,
  memoryWarnRatio: memoryWarnRatio,
  memoryDangerRatio: memoryDangerRatio,
  showAllTimeStats: showAllTimeStats,
  jankBurstWindow: jankBurstWindow,
  jankBurstCooldown: jankBurstCooldown,
);

void main() {
  group('PerformanceOverlayConfig', () {
    test('equal values compare equal with the same hash', () {
      expect(_config(), _config());
      expect(_config().hashCode, _config().hashCode);
    });

    final variants = <String, PerformanceOverlayConfig>{
      'sampleSize': _config(sampleSize: 32),
      'target': _config(target: const Duration(microseconds: 8333)),
      'refreshRate': _config(refreshRate: 120),
      'barRangeMax': _config(barRangeMax: const Duration(milliseconds: 40)),
      'backgroundColor': _config(backgroundColor: Colors.grey),
      'textColor': _config(textColor: Colors.white),
      'uiColor': _config(uiColor: Colors.green),
      'rasterColor': _config(rasterColor: Colors.orange),
      'totalColor': _config(totalColor: Colors.pink),
      'overTargetColor': _config(overTargetColor: Colors.amber),
      'compact': _config(compact: true),
      'showP90': _config(showP90: true),
      'allowFreeze': _config(allowFreeze: false),
      'enableJankLogging': _config(enableJankLogging: true),
      'severeJankFactor': _config(severeJankFactor: 3),
      'jankLogCooldown': _config(jankLogCooldown: Duration.zero),
      'showMemory': _config(showMemory: false),
      'memoryWarnRatio': _config(memoryWarnRatio: 1.5),
      'memoryDangerRatio': _config(memoryDangerRatio: 3),
      'showAllTimeStats': _config(showAllTimeStats: true),
      'jankBurstWindow': _config(jankBurstWindow: 5),
      'jankBurstCooldown': _config(jankBurstCooldown: Duration.zero),
    };

    for (final MapEntry(:key, :value) in variants.entries) {
      test('a different $key is not equal', () {
        expect(value, isNot(_config()));
      });
    }
  });
}
