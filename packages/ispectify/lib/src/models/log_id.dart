import 'dart:math';

/// Generates ULID-style identifiers for log entries.
///
/// A ULID is a 26-character, lexicographically sortable identifier composed of
/// a 48-bit millisecond timestamp followed by 80 bits of randomness, encoded
/// with Crockford's base32 alphabet. See https://github.com/ulid/spec.
///
/// Sorting two ULIDs as strings preserves chronological order down to the
/// millisecond, which matches how log history is browsed. The randomness tail
/// keeps ids globally unique across processes, isolates, sessions, and reloaded
/// log files — `(sessionId, sequence)` is no longer needed for disambiguation.
abstract final class LogId {
  /// Crockford's base32 alphabet — excludes I, L, O, U to reduce ambiguity.
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Cryptographically secure RNG so ids stay unique across forked processes
  /// and replayed sessions.
  static final Random _random = Random.secure();

  /// Returns a fresh 26-character ULID.
  static String generate() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();

    // Timestamp: 48 bits → 10 base32 chars, big-endian. The top 2 bits are
    // always zero because 48 < 50, which keeps the encoding ULID-spec compliant.
    var timestamp = ms;
    final timeChars = List<String>.filled(10, '0');
    for (var i = 9; i >= 0; i--) {
      timeChars[i] = _alphabet[timestamp & 0x1F];
      timestamp >>= 5;
    }
    buffer.writeAll(timeChars);

    // Randomness: 80 bits → 16 base32 chars (each draw consumes 5 bits).
    for (var i = 0; i < 16; i++) {
      buffer.write(_alphabet[_random.nextInt(32)]);
    }

    return buffer.toString();
  }
}
