import 'package:ispectify/src/network/filter/network_filter.dart';

/// Logs only every [sampleRate]-th event (1-based counting).
///
/// This is the only intentionally stateful built-in filter - it maintains
/// an internal counter. All other filters are stateless.
class SamplingFilter<T> extends NetworkFilter<T> {
  /// Throws [ArgumentError] when [sampleRate] is less than 1.
  SamplingFilter({required this.sampleRate}) {
    if (sampleRate < 1) {
      throw ArgumentError.value(sampleRate, 'sampleRate', 'must be at least 1');
    }
  }

  /// Log every N-th call (e.g. `sampleRate: 10` logs 10th, 20th, …).
  final int sampleRate;

  int _counter = 0;

  @override
  bool apply(T value) {
    _counter++;
    return _counter % sampleRate == 0;
  }
}
