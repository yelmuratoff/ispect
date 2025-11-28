import 'package:ispectify/src/redaction/strategies/redaction_strategy.dart';

/// Runs multiple strategies in order and returns the first redaction result.
class CompositeRedactionStrategy implements RedactionStrategy {
  CompositeRedactionStrategy(this._strategies);

  final List<RedactionStrategy> _strategies;

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionRuntime runtime,
    String? keyName,
  }) {
    for (final s in _strategies) {
      final out = s.tryRedact(node, runtime: runtime, keyName: keyName);
      if (out != null) return out;
    }
    return null;
  }
}
