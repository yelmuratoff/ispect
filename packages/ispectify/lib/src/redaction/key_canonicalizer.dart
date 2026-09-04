final RegExp _acronymBoundary = RegExp('([A-Z]+)([A-Z][a-z])');
final RegExp _camelBoundary = RegExp('([a-z0-9])([A-Z])');
final RegExp _bracketBoundary = RegExp(r'\[([^\[\]]*)\]');

/// Rewrites [key] as lower-case snake-case segments.
///
/// camelCase and acronym boundaries, dotted and dashed separators, and
/// bracketed path segments all become `_`, so `headers.X-Api-Key` and
/// `headers[xApiKey]` canonicalize to the same `headers_x_api_key`.
String canonicalizeKey(String key) => key
    .trim()
    .replaceAllMapped(_acronymBoundary, (m) => '${m[1]}_${m[2]}')
    .replaceAllMapped(_camelBoundary, (m) => '${m[1]}_${m[2]}')
    .replaceAllMapped(
      _bracketBoundary,
      (m) => m[1]!.isEmpty ? '' : '_${m[1]}',
    )
    .replaceAll('.', '_')
    .replaceAll('-', '_')
    .toLowerCase();
