import 'package:ispectify/src/redaction/scrub/code_units.dart';

/// Percent-decoding helpers shared by URL and assignment scrubbing.
abstract final class UrlComponentCodec {
  static const int maxKeyDecodePasses = 5;

  static final RegExp malformedPercentEncoding = RegExp(
    '%(?![0-9A-Fa-f]{2})',
  );

  static String? tryDecode(String value) {
    if (UrlComponentCodec.malformedPercentEncoding.hasMatch(value)) return null;
    try {
      return Uri.decodeQueryComponent(value);
    } on Object {
      return null;
    }
  }

  static String? decodeKey(String value) {
    var decoded = value;
    for (var depth = 0; depth < maxKeyDecodePasses; depth++) {
      final candidate = UrlComponentCodec.tryDecode(decoded);
      if (candidate == null) return null;
      if (candidate == decoded) return decoded;
      decoded = candidate;
    }

    final remaining = UrlComponentCodec.tryDecode(decoded);
    if (remaining == null || remaining != decoded) return null;
    return decoded;
  }

  static String mapParameterSegments(
    String value,
    String Function(String pair) transform,
  ) {
    final output = StringBuffer();
    var segmentStart = 0;
    for (var index = 0; index <= value.length; index++) {
      final isEnd = index == value.length;
      if (!isEnd) {
        final codeUnit = value.codeUnitAt(index);
        if (codeUnit != CodeUnits.ampersand &&
            codeUnit != CodeUnits.semicolon) {
          continue;
        }
      }

      output.write(transform(value.substring(segmentStart, index)));
      if (!isEnd) output.writeCharCode(value.codeUnitAt(index));
      segmentStart = index + 1;
    }
    return output.toString();
  }

  /// Finds HTTP(S) URLs embedded in [text] and redacts their query parameters
  /// and userInfo credentials.
  ///
  /// Useful for sanitizing error messages that may contain full URLs with
}
