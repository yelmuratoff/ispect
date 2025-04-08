import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Generates a text file containing the provided `logs` and saves it in the temporary directory.
///
/// This function creates a file in the system's temporary directory and writes the given
/// `logs` into it. The file is named using an optional [name] prefix (default: `'ispect'`),
/// followed by a timestamp to ensure uniqueness.
///
/// ### Parameters:
/// - `logs`: The content to be written to the file (required).
/// - `name`: An optional prefix for the file name (default: `'ispect'`).
///
/// ### File Naming Convention:
/// The generated file name follows this format:
/// ```
/// {name}-{timestamp}.txt
/// ```
/// - The timestamp is formatted as `yyyy-MM-dd HH-mm-ss.SSS` (with `:` replaced by `-`).
///
/// ### Example:
/// ```dart
/// File logFile = await generateFile("Sample log data", name: "log");
/// print("File created: ${logFile.path}");
/// ```
///
/// ### Behavior:
/// - Retrieves the system's temporary directory.
/// - Generates a timestamped file name.
/// - Creates the file (including parent directories if needed).
/// - Writes the given `logs` to the file.
/// - Returns the created `File` instance.
///
/// **Note:**
/// The file is stored in the temporary directory, meaning it may be deleted
/// by the system at any time.
Future<File> generateFile(
  String logs, {
  String? name = 'ispect',
}) async {
  try {
    final dir = await getTemporaryDirectory();
    final dirPath = dir.path;

    // Format the current timestamp, replacing colons to ensure valid filenames.
    final fmtDate = DateTime.now().toString().replaceAll(':', '-');

    // Construct the full file path.
    final filePath = '$dirPath/$name-$fmtDate.txt';

    // Create the file and write the logs.
    final file = await File(filePath).create(recursive: true);
    await file.writeAsString(logs);

    return file;
  } catch (_) {
    rethrow;
  }
}
