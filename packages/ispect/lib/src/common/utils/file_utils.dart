import 'dart:io';
import 'dart:typed_data';

import 'package:ispect/src/core/platform/platform_directory.dart';

/// A utility class for file-related operations.
///
/// This class provides methods for writing image data to storage,
/// particularly for handling feedback screenshots.
///
/// **Note:** This class cannot be instantiated.
final class ISpectFileUtils {
  /// Private constructor to prevent instantiation.
  const ISpectFileUtils._();

  /// Writes the given `feedbackScreenshot` (as `Uint8List`) to a temporary storage location
  /// and returns a `File` instance pointing to the stored file.
  ///
  /// ### Parameters:
  /// - `feedbackScreenshot`: The raw image bytes to be saved as a file.
  ///
  /// ### Behavior:
  /// - Retrieves the system's temporary directory.
  /// - Generates a unique file name using the image hash code.
  /// - Saves the image as a `.png` file.
  /// - Returns an `XFile` object representing the saved image.
  ///
  /// ### Example:
  /// ```dart
  /// Uint8List screenshotBytes = await captureScreenshot();
  /// File screenshotFile = await ISpectFileUtils.writeImageToStorage(screenshotBytes);
  /// print("Screenshot saved at: ${screenshotFile.path}");
  /// ```
  ///
  /// **Note:** The file is stored in the temporary directory, meaning it may
  /// be deleted by the system at any time. If persistent storage is required,
  /// consider using `getApplicationDocumentsDirectory()`.
  ///
  /// Throws an `IOException` if file creation or writing fails.
  static Future<File> writeImageToStorage(Uint8List feedbackScreenshot) async {
    // Retrieve the system's temporary directory.
    final output =
        (await platformDirectoryProvider.tempDirectory()) as Directory;

    // Generate a unique file name based on the screenshot's hash code.
    final screenshotFilePath =
        '${output.path}/feedback${feedbackScreenshot.hashCode}.png';

    // Create and write the image file.
    final screenshotFile = File(screenshotFilePath);
    await screenshotFile.writeAsBytes(feedbackScreenshot);

    // Return the saved file reference.
    return screenshotFile;
  }
}
