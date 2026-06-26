/// The single placeholder substituted for every redacted value across all
/// ispect packages — network, database, export, clipboard, and cURL.
///
/// This is the single source of truth for the redaction mask; do not introduce
/// alternative masks. The only deliberate variant is
/// [userInfoRedactedPlaceholder], which drops the brackets that [Uri.replace]
/// cannot encode.
const String defaultPlaceholder = '[REDACTED]';

/// Deprecated alias of [defaultPlaceholder].
///
/// Kept so existing imports keep compiling; all redaction now emits the single
/// [defaultPlaceholder] mask.
@Deprecated('Use defaultPlaceholder; redaction now uses one unified mask.')
const String redactedMask = defaultPlaceholder;

/// URI-safe form of [defaultPlaceholder] for redacted userInfo in URLs.
///
/// `Uri.replace` throws a [FormatException] on the brackets in
/// [defaultPlaceholder], so URL credentials use this bracketless variant —
/// e.g. `https://REDACTED@host`.
const String userInfoRedactedPlaceholder = 'REDACTED';

/// Placeholder returned when redaction itself throws an exception.
const String redactionFailedPlaceholder = '<redaction-failed>';

/// Placeholder used when map/data conversion fails during sanitization.
const String conversionFailedPlaceholder = '[conversion failed]';

/// Placeholder for redacted binary data, preserving the original byte count.
String binaryPlaceholder(int length) => '[binary $length bytes]';

/// Placeholder for redacted Base64-encoded data, showing approximate length.
String base64Placeholder(int length) => '[base64 ~${length}B]';
