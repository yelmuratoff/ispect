/// Immutable snapshot of [RedactionService] configuration.
///
/// Passed to [RedactionWalker] so that mutation on the service does not affect
/// an in-flight traversal.
final class RedactionConfig {
  const RedactionConfig({
    required this.sensitiveKeysLower,
    required this.sensitiveKeyPatterns,
    required this.maxDepth,
    required this.visibleEdgeLength,
    required this.placeholder,
    required this.redactBinary,
    required this.redactBase64,
    required this.ignoredValues,
    required this.ignoredKeyNamesLower,
    required this.fullyMaskedKeyNamesLower,
  });

  final Set<String> sensitiveKeysLower;
  final List<RegExp> sensitiveKeyPatterns;
  final int maxDepth;
  final int visibleEdgeLength;
  final String placeholder;
  final bool redactBinary;
  final bool redactBase64;
  final Set<String> ignoredValues;
  final Set<String> ignoredKeyNamesLower;
  final Set<String> fullyMaskedKeyNamesLower;

  RedactionConfig copyWithIgnoredValues(Set<String> newIgnoredValues) =>
      RedactionConfig(
        sensitiveKeysLower: sensitiveKeysLower,
        sensitiveKeyPatterns: sensitiveKeyPatterns,
        maxDepth: maxDepth,
        visibleEdgeLength: visibleEdgeLength,
        placeholder: placeholder,
        redactBinary: redactBinary,
        redactBase64: redactBase64,
        ignoredValues: newIgnoredValues,
        ignoredKeyNamesLower: ignoredKeyNamesLower,
        fullyMaskedKeyNamesLower: fullyMaskedKeyNamesLower,
      );

  RedactionConfig copyWithIgnoredKeys(Set<String> newIgnoredKeys) =>
      RedactionConfig(
        sensitiveKeysLower: sensitiveKeysLower,
        sensitiveKeyPatterns: sensitiveKeyPatterns,
        maxDepth: maxDepth,
        visibleEdgeLength: visibleEdgeLength,
        placeholder: placeholder,
        redactBinary: redactBinary,
        redactBase64: redactBase64,
        ignoredValues: ignoredValues,
        ignoredKeyNamesLower: newIgnoredKeys,
        fullyMaskedKeyNamesLower: fullyMaskedKeyNamesLower,
      );
}
