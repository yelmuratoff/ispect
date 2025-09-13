import 'package:flutter/material.dart';

class ParametersCard extends StatelessWidget {
  final int requestCount;
  final int itemCount;
  final int nestingDepth;
  final int payloadSize;
  final int wsMessageSize;
  final int loopDelayMs;
  final String httpMethod;
  final String preset;
  final bool useAuthHeader;
  final bool randomize;
  final ValueChanged<int> onRequestCountChanged;
  final ValueChanged<int> onItemCountChanged;
  final ValueChanged<int> onNestingDepthChanged;
  final ValueChanged<int> onPayloadSizeChanged;
  final ValueChanged<int> onWsMessageSizeChanged;
  final ValueChanged<int> onLoopDelayMsChanged;
  final ValueChanged<String> onHttpMethodChanged;
  final ValueChanged<String> onPresetChanged;
  final ValueChanged<bool> onUseAuthHeaderChanged;
  final ValueChanged<bool> onRandomizeChanged;

  const ParametersCard({
    super.key,
    required this.requestCount,
    required this.itemCount,
    required this.nestingDepth,
    required this.payloadSize,
    required this.wsMessageSize,
    required this.loopDelayMs,
    required this.httpMethod,
    required this.preset,
    required this.useAuthHeader,
    required this.randomize,
    required this.onRequestCountChanged,
    required this.onItemCountChanged,
    required this.onNestingDepthChanged,
    required this.onPayloadSizeChanged,
    required this.onWsMessageSizeChanged,
    required this.onLoopDelayMsChanged,
    required this.onHttpMethodChanged,
    required this.onPresetChanged,
    required this.onUseAuthHeaderChanged,
    required this.onRandomizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parameters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildSlider(
              context,
              label: 'Request Count',
              value: requestCount.toDouble(),
              min: 1,
              max: 10,
              onChanged: (v) => onRequestCountChanged(v.toInt()),
            ),
            _buildSlider(
              context,
              label: 'Item Count',
              value: itemCount.toDouble(),
              min: 10,
              max: 1000,
              onChanged: (v) => onItemCountChanged(v.toInt()),
            ),
            _buildSlider(
              context,
              label: 'Nesting Depth',
              value: nestingDepth.toDouble(),
              min: 1,
              max: 10,
              onChanged: (v) => onNestingDepthChanged(v.toInt()),
            ),
            _buildSlider(
              context,
              label: 'HTTP Payload Size',
              value: payloadSize.toDouble(),
              min: 0,
              max: 512,
              onChanged: (v) => onPayloadSizeChanged(v.toInt()),
            ),
            _buildSlider(
              context,
              label: 'WS Message Size',
              value: wsMessageSize.toDouble(),
              min: 4,
              max: 128,
              onChanged: (v) => onWsMessageSizeChanged(v.toInt()),
            ),
            _buildSlider(
              context,
              label: 'Delay per Iteration (ms)',
              value: loopDelayMs.toDouble(),
              min: 0,
              max: 500,
              onChanged: (v) => onLoopDelayMsChanged(v.toInt()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: httpMethod,
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: const [
                      DropdownMenuItem(value: 'GET', child: Text('GET')),
                      DropdownMenuItem(value: 'POST', child: Text('POST')),
                      DropdownMenuItem(value: 'PUT', child: Text('PUT')),
                      DropdownMenuItem(value: 'DELETE', child: Text('DELETE')),
                    ],
                    onChanged: (v) => onHttpMethodChanged(v ?? 'GET'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: preset,
                    decoration: const InputDecoration(labelText: 'Preset'),
                    items: const [
                      DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                      DropdownMenuItem(value: 'Light', child: Text('Light')),
                      DropdownMenuItem(value: 'Stress', child: Text('Stress')),
                      DropdownMenuItem(
                          value: 'Network', child: Text('Network')),
                      DropdownMenuItem(value: 'Full', child: Text('Full')),
                    ],
                    onChanged: (v) => onPresetChanged(v ?? 'Custom'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              value: useAuthHeader,
              onChanged: onUseAuthHeaderChanged,
              title: const Text('Use Authorization Header'),
              dense: true,
            ),
            SwitchListTile(
              value: randomize,
              onChanged: onRandomizeChanged,
              title: const Text('Randomize Values'),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toInt().toString()),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
