/// Placeholder key for map keys whose type cannot be rendered safely.
const String unprintableMapKey = '<unprintable-key>';

/// Renders a map key for a redacted copy without dispatching into caller
/// code; only closed scalar families are printable.
({String value, bool isSafe}) safeMapKey(Object? key) => switch (key) {
      String() => (value: key, isSafe: true),
      null => (value: 'null', isSafe: true),
      bool() => (value: key ? 'true' : 'false', isSafe: true),
      num() => (value: key.toString(), isSafe: true),
      Enum() => (value: key.name, isSafe: true),
      _ => (value: unprintableMapKey, isSafe: false),
    };
