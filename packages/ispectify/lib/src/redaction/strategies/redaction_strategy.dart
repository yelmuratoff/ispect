import 'package:ispectify/src/redaction/strategies/redaction_context.dart';

export 'package:ispectify/src/redaction/strategies/redaction_context.dart';

/// Redaction strategy interface.
///
/// Implementations return a non-null value when they apply a redaction to the
/// given node in the provided context. Returning `null` means "no opinion" and
/// allows other strategies or fallback traversal to handle it.
abstract class RedactionStrategy {
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  });
}
