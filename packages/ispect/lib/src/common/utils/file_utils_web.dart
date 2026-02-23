import 'dart:typed_data';

/// A utility class for file-related operations on Web platforms.
final class ISpectFileUtils {
  const ISpectFileUtils._();

  /// Unsupported on the web.
  static Future<dynamic> writeImageToStorage(
    Uint8List feedbackScreenshot,
  ) async {
    throw UnsupportedError('File operations are not supported on the Web.');
  }
}
