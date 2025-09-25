import 'package:flutter/material.dart';

class StreamCard extends StatelessWidget {
  final bool streamMode;
  final int intervalMs;
  final ValueChanged<bool> onStreamModeChanged;
  final ValueChanged<int> onIntervalChanged;

  const StreamCard({
    super.key,
    required this.streamMode,
    required this.intervalMs,
    required this.onStreamModeChanged,
    required this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stream Mode', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable periodic generation'),
              value: streamMode,
              onChanged: onStreamModeChanged,
              dense: true,
            ),
            const SizedBox(height: 8),
            _IntervalSlider(
              value: intervalMs,
              onChanged: onIntervalChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntervalSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _IntervalSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Stream Interval (ms)'),
            Text(value.toString()),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 250,
          max: 5000,
          divisions: ((5000 - 250) / 250).round(),
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }
}
