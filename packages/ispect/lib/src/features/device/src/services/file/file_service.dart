import 'dart:io';

import 'package:ispect/ispect.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Abstract interface defining core file system operations for the application.
///
/// This service provides a contract for managing application directories and files,
/// including cache cleanup and file enumeration operations.
abstract interface class BaseFileService {
  /// Deletes the entire cache directory and all its contents.
  ///
  /// This operation removes temporary files stored in the system's
  /// temporary directory for this application.
  Future<void> deleteCacheDir();

  /// Deletes the entire application support directory and all its contents.
  ///
  /// This operation removes persistent application data stored in the
  /// system's application support directory.
  Future<void> deleteAppDir();

  /// Retrieves a list of valid files from the cache directory.
  ///
  /// Returns only files that exist, are not directories, and have
  /// a valid file extension.
  ///
  /// Returns an empty list if the operation fails or no valid files are found.
  Future<List<File>> getFiles();
}

/// Concrete implementation of [BaseFileService] for application file operations.
///
/// This service manages file system operations including directory cleanup
/// and file enumeration. Implements the singleton pattern to ensure
/// consistent file system access throughout the application.
///
/// All operations are wrapped in try-catch blocks and failures are logged
/// through the ISpect logger system for debugging purposes.
class AppFileService implements BaseFileService {
  /// Private constructor to prevent external instantiation.
  const AppFileService._();

  /// Singleton instance of the file service.
  static const BaseFileService _instance = AppFileService._();

  /// Provides access to the singleton instance of the file service.
  static BaseFileService get instance => _instance;

  @override
  Future<void> deleteAppDir() async {
    try {
      // Get the application support directory path
      final appDir = await getApplicationSupportDirectory();

      // Check if directory exists before attempting deletion
      if (appDir.existsSync()) {
        // Recursively delete the entire directory and its contents
        await appDir.delete(recursive: true);
      }
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to delete application support directory',
      );
    }
  }

  @override
  Future<void> deleteCacheDir() async {
    try {
      // Get the temporary directory path used for caching
      final cacheDir = await getTemporaryDirectory();

      // Check if directory exists before attempting deletion
      if (cacheDir.existsSync()) {
        // Recursively delete the entire cache directory and its contents
        await cacheDir.delete(recursive: true);
      }
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to delete cache directory',
      );
    }
  }

  @override
  Future<List<File>> getFiles() async {
    try {
      // Get the temporary directory where cached files are stored
      final cacheDir = await getTemporaryDirectory();

      // List all entities (files and directories) in the cache directory
      final entities = cacheDir.listSync();

      // Filter and collect only valid files
      final validFiles = <File>[];
      for (final entity in entities) {
        // Check if entity is a file and passes validation criteria
        if (entity is File && _isValidFileSync(entity)) {
          validFiles.add(entity);
        }
      }

      return validFiles;
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to get files from cache directory',
      );
      return <File>[];
    }
  }

  /// Validates whether a file meets the criteria for being considered valid.
  ///
  /// A file is considered valid if:
  /// - It exists on the file system
  /// - It is not a directory
  /// - It has a non-empty file extension
  ///
  /// Parameters:
  /// - [file]: The file to validate
  ///
  /// Returns: true if the file meets all validation criteria, false otherwise
  bool _isValidFileSync(File file) =>
      file.existsSync() &&
      !FileSystemEntity.isDirectorySync(file.path) &&
      p.extension(file.path).isNotEmpty;
}
