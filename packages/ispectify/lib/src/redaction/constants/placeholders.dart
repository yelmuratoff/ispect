/// Default placeholder text substituted for redacted values.
const String defaultPlaceholder = '[REDACTED]';

/// Short mask used for key-based redaction (e.g. passwords, tokens).
const String redactedMask = '***';

/// URI-safe placeholder for redacted userInfo (username:password) in URLs.
///
/// Avoids brackets and special characters that would cause [Uri.replace] to
/// throw a [FormatException].
const String userInfoRedactedPlaceholder = 'REDACTED';

/// Placeholder returned when redaction itself throws an exception.
const String redactionFailedPlaceholder = '<redaction-failed>';

/// Placeholder used when map/data conversion fails during sanitization.
const String conversionFailedPlaceholder = '[conversion failed]';

/// Placeholder for redacted binary data, preserving the original byte count.
String binaryPlaceholder(int length) => '[binary $length bytes]';

/// Placeholder for redacted Base64-encoded data, showing approximate length.
String base64Placeholder(int length) => '[base64 ~${length}B]';
