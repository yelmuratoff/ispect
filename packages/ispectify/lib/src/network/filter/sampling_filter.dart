import 'package:ispectify/src/network/filter/network_filter.dart';

/// Logs only every [sampleRate]-th event (1-based counting).
///
/// This is the only intentionally stateful built-in filter — it maintains
/// an internal counter. All other filters are stateless.
class SamplingFilter<T> extends NetworkFilter<T> {
  SamplingFilter({required this.sampleRate}) : assert(sampleRate > 0);

  /// Log every N-th call (e.g. `sampleRate: 10` logs 10th, 20th, …).
  final int sampleRate;

  int _counter = 0;

  @override
  bool apply(T value) {
    _counter++;
    return _counter % sampleRate == 0;
  }
}
