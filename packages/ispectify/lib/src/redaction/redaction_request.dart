/// Per-call overrides for ignored values and keys.
final class RedactionRequest {
  const RedactionRequest._({
    this.ignoredValues,
    this.ignoredKeysLower,
  });

  factory RedactionRequest.fromOverrides(
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
  ) {
    final normalizedValues = (ignoredValues == null || ignoredValues.isEmpty)
        ? null
        : Set<String>.unmodifiable(ignoredValues);
    final normalizedKeys = (ignoredKeys == null || ignoredKeys.isEmpty)
        ? null
        : Set<String>.unmodifiable(
            ignoredKeys.map((e) => e.toLowerCase()),
          );
    if (normalizedValues == null && normalizedKeys == null) {
      return empty;
    }
    return RedactionRequest._(
      ignoredValues: normalizedValues,
      ignoredKeysLower: normalizedKeys,
    );
  }

  static const empty = RedactionRequest._();

  final Set<String>? ignoredValues;
  final Set<String>? ignoredKeysLower;
}
