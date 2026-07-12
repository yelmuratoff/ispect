import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _frameBudget = Duration(milliseconds: 16);
const _eventCount = 2000;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'records frame timings for fixed high-volume events with filters on and off',
    (tester) async {
      final timings = <FrameTiming>[];
      void collectTimings(List<FrameTiming> values) {
        timings.addAll(values);
      }

      SchedulerBinding.instance.addTimingsCallback(collectTimings);
      addTearDown(
        () => SchedulerBinding.instance.removeTimingsCallback(collectTimings),
      );

      await tester.pumpWidget(const _ProfileScenario());
      await tester.pumpAndSettle();
      expect(find.text('Visible events: $_eventCount'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('filter-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Visible events: 200'), findsOneWidget);

      binding.reportData = <String, Object>{
        'high-volume-profile': _FrameSummary.from(timings).toJson(),
      };
    },
    skip: !kProfileMode,
  );
}

class _ProfileScenario extends StatefulWidget {
  const _ProfileScenario();

  @override
  State<_ProfileScenario> createState() => _ProfileScenarioState();
}

class _ProfileScenarioState extends State<_ProfileScenario> {
  final List<_ProfileEvent> _events = <_ProfileEvent>[];
  late final StreamSubscription<List<_ProfileEvent>> _eventSubscription;
  var _filtersEnabled = false;

  @override
  void initState() {
    super.initState();
    _eventSubscription = _fixedEventStream().listen((batch) {
      if (!mounted) return;
      setState(() => _events.addAll(batch));
    });
  }

  @override
  void dispose() {
    unawaited(_eventSubscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = _filtersEnabled
        ? _events.where((event) => event.isError).toList(growable: false)
        : _events;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ISpect profile benchmark')),
        body: Column(
          children: <Widget>[
            Text('Visible events: ${visibleEvents.length}'),
            FilledButton(
              key: const ValueKey<String>('filter-toggle'),
              onPressed: () {
                setState(() => _filtersEnabled = !_filtersEnabled);
              },
              child:
                  Text(_filtersEnabled ? 'Disable filters' : 'Enable filters'),
            ),
            Expanded(
              child: ListView.builder(
                itemExtent: 36,
                itemCount: visibleEvents.length,
                itemBuilder: (context, index) {
                  final event = visibleEvents[index];
                  return ListTile(
                    title: Text(event.message),
                    trailing: Text(event.isError ? 'error' : 'info'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Stream<List<_ProfileEvent>> _fixedEventStream() async* {
  const batchSize = 100;
  for (var firstIndex = 0; firstIndex < _eventCount; firstIndex += batchSize) {
    yield List<_ProfileEvent>.generate(
      batchSize,
      (offset) {
        final index = firstIndex + offset;
        return _ProfileEvent(index, isError: index % 10 == 0);
      },
      growable: false,
    );
    await Future<void>.delayed(Duration.zero);
  }
}

final class _ProfileEvent {
  const _ProfileEvent(this.index, {required this.isError});

  final int index;
  final bool isError;

  String get message => 'Synthetic benchmark event $index';
}

final class _FrameSummary {
  const _FrameSummary({
    required this.frameCount,
    required this.missedFrameCount,
    required this.maxBuildMicros,
    required this.maxRasterMicros,
  });

  factory _FrameSummary.from(List<FrameTiming> timings) {
    var maxBuildMicros = 0;
    var maxRasterMicros = 0;
    var missedFrameCount = 0;
    for (final timing in timings) {
      maxBuildMicros =
          _max(maxBuildMicros, timing.buildDuration.inMicroseconds);
      maxRasterMicros =
          _max(maxRasterMicros, timing.rasterDuration.inMicroseconds);
      if (timing.totalSpan > _frameBudget) missedFrameCount++;
    }
    return _FrameSummary(
      frameCount: timings.length,
      missedFrameCount: missedFrameCount,
      maxBuildMicros: maxBuildMicros,
      maxRasterMicros: maxRasterMicros,
    );
  }

  final int frameCount;
  final int missedFrameCount;
  final int maxBuildMicros;
  final int maxRasterMicros;

  Map<String, int> toJson() => <String, int>{
        'frame-count': frameCount,
        'missed-frame-count': missedFrameCount,
        'max-build-micros': maxBuildMicros,
        'max-raster-micros': maxRasterMicros,
      };
}

int _max(int left, int right) => left > right ? left : right;
