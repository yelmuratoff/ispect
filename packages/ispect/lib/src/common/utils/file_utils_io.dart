import 'dart:io';
import 'dart:typed_data';

import 'package:ispect/src/core/platform/platform_directory.dart';

/// A utility class for file-related operations on Native platforms.
final class ISpectFileUtils {
  const ISpectFileUtils._();

  /// Writes [feedbackScreenshot] to a temporary directory and returns the [File].
  ///
  /// Throws [FileSystemException] if the write operation fails.
  static Future<File> writeImageToStorage(Uint8List feedbackScreenshot) async {
    final output = await platformDirectoryProvider.tempDirectory();
    if (output is! Directory) {
      throw const FileSystemException(
        'Failed to get temporary directory',
      );
    }
    final screenshotFilePath =
        '${output.path}/feedback${feedbackScreenshot.hashCode}.png';

    final screenshotFile = File(screenshotFilePath);
    await screenshotFile.writeAsBytes(feedbackScreenshot);

    return screenshotFile;
  }
}
