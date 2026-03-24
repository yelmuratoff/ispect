/// Default placeholder text substituted for redacted values.
const String defaultPlaceholder = '[REDACTED]';

/// Placeholder for redacted binary data, preserving the original byte count.
String binaryPlaceholder(int length) => '[binary $length bytes]';

/// Placeholder for redacted Base64-encoded data, showing approximate length.
String base64Placeholder(int length) => '[base64 ~${length}B]';
