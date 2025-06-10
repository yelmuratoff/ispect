import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:ispect/ispect.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Abstract interface defining core cache management operations for the application.
///
/// This service provides a contract for managing application cache directories,
/// calculating cache sizes, and formatting size information for display.
/// Implementations should handle both system-level caches and Flutter-specific caches.
abstract interface class BaseCacheService {
  /// Deletes all cache directories and clears image cache
  ///
  /// This operation removes:
  /// - Temporary directory cache
  /// - Application cache directory
  /// - Android external cache directories (if applicable)
  /// - Flutter's in-memory image cache
  Future<void> deleteCacheDir();

  /// Returns the total cache size in bytes
  ///
  /// Calculates the combined size of all cache directories by recursively
  /// scanning and summing file sizes. Returns 0.0 if calculation fails.
  Future<double> getCacheSize();

  /// Formats the size in bytes into a human-readable string (MB/GB)
  ///
  /// Parameters:
  /// - [sizeInBytes]: The size value to format
  ///
  /// Returns: Formatted string with appropriate unit (MB for < 1GB, GB for >= 1GB)
  String formatSize(double sizeInBytes);
}

/// Concrete implementation of [BaseCacheService] for comprehensive cache management.
///
/// This service manages all aspects of application caching including:
/// - System cache directories (temporary and application cache)
/// - Android external cache directories (platform-specific)
/// - Flutter's in-memory image cache
///
/// Features:
/// - Parallel processing for improved performance
/// - Comprehensive error handling and logging
/// - Platform-aware operations (Android-specific functionality)
/// - Robust file validation and size calculation
///
/// All operations are resilient to failures and will log errors without
/// throwing exceptions to ensure application stability.
final class AppCacheManager implements BaseCacheService {
  /// Creates a new instance of the cache manager.
  ///
  /// Uses const constructor for better performance and immutability.
  const AppCacheManager();

  @override
  Future<void> deleteCacheDir() async {
    try {
      // Process directory deletions in parallel for better performance
      // Each operation is independent and can run concurrently
      await Future.wait([
        _deleteMainCacheDirectories(),
        _deleteAndroidExternalDirectories(),
        _clearImageCache(),
      ]);

      // Log successful completion of all cache clearing operations
      ISpect.logger.info('Successfully cleared all cache directories');
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to clear cache',
      );
    }
  }

  /// Deletes main cache directories (temp and app cache)
  ///
  /// Handles the deletion of:
  /// - Temporary directory: System temp storage for the app
  /// - Application cache directory: App-specific cache storage
  ///
  /// Uses parallel processing to delete multiple directories simultaneously
  /// for improved performance. Each directory access is wrapped in try-catch
  /// to ensure one failure doesn't prevent other directories from being cleaned.
  Future<void> _deleteMainCacheDirectories() async {
    final futures = <Future<void>>[];

    // Handle temporary directory deletion
    try {
      final cacheDir = await getTemporaryDirectory();
      // Check existence before adding to futures list to avoid unnecessary operations
      if (await cacheDir.exists()) {
        futures.add(_deleteSingleDirectory(cacheDir, 'cacheDir'));
      }
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to access temporary directory',
      );
    }

    // Handle application cache directory deletion
    try {
      final appCacheDir = await getApplicationCacheDirectory();
      // Check existence before adding to futures list
      if (await appCacheDir.exists()) {
        futures.add(_deleteSingleDirectory(appCacheDir, 'appCacheDir'));
      }
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to access application cache directory',
      );
    }

    // Execute all deletion operations in parallel if any directories were found
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Deletes Android external cache directories if on Android platform
  ///
  /// Android apps can have multiple external cache directories (e.g., SD cards).
  /// This method handles platform-specific cache cleanup by:
  /// - Checking if running on Android platform
  /// - Retrieving all external cache directories
  /// - Deleting each directory in parallel for performance
  ///
  /// Gracefully handles cases where external storage is unavailable.
  Future<void> _deleteAndroidExternalDirectories() async {
    // Early return for non-Android platforms to avoid unnecessary work
    if (!Platform.isAndroid) return;

    try {
      // Get all external cache directories (can be null or empty)
      final externalDirs = await getExternalCacheDirectories();

      // Handle cases where no external directories are available
      if (externalDirs == null || externalDirs.isEmpty) return;

      // Create parallel deletion tasks for all external directories
      final futures = externalDirs
          .map((dir) => _deleteSingleDirectory(dir, 'externalDir'))
          .toList();

      // Execute all deletions concurrently
      await Future.wait(futures);
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to access external cache directories',
      );
    }
  }

  /// Deletes a single directory with comprehensive error handling
  ///
  /// This utility method provides safe directory deletion with:
  /// - Existence verification before deletion attempt
  /// - Recursive deletion to remove all contents
  /// - Detailed logging for debugging and monitoring
  /// - Error isolation to prevent cascade failures
  ///
  /// Parameters:
  /// - [dir]: The directory to delete
  /// - [dirType]: Human-readable type identifier for logging
  Future<void> _deleteSingleDirectory(Directory dir, String dirType) async {
    try {
      // Verify directory still exists before attempting deletion
      // (it may have been deleted by another process)
      if (await dir.exists()) {
        // Recursively delete directory and all its contents
        await dir.delete(recursive: true);

        // Log successful deletion with path for debugging
        ISpect.logger.info('Cleared: $dirType: ${dir.path}');
      }
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to delete $dirType: ${dir.path}',
      );
    }
  }

  /// Clears Flutter's in-memory image cache
  ///
  /// Flutter maintains an in-memory cache of decoded images for performance.
  /// This method clears both:
  /// - Regular image cache: Cached decoded images
  /// - Live images: Currently displayed images that are kept in memory
  ///
  /// This is important for freeing up memory and ensuring fresh image loading
  /// when cache is cleared by the user.
  Future<void> _clearImageCache() async {
    try {
      // Get the singleton image cache instance and perform cascaded clearing
      final imageCache = PaintingBinding.instance.imageCache
        ..clear() // Clear cached decoded images
        ..clearLiveImages(); // Clear live/active images

      // Log cache clearing with before/after statistics for monitoring
      ISpect.logger.info(
        'Cleared: imageCache: ${imageCache.currentSize}, '
        'clearLiveImages: ${imageCache.liveImageCount}',
      );
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to clear image cache',
      );
    }
  }

  @override
  Future<double> getCacheSize() async {
    try {
      final futures = <Future<double>>[];

      // Calculate directory sizes in parallel for better performance
      // Each directory size calculation is independent and can run concurrently

      // Handle temporary directory size calculation
      try {
        final cacheDir = await getTemporaryDirectory();
        // Only calculate size if directory exists
        if (await cacheDir.exists()) {
          futures.add(_getDirSize(cacheDir));
        }
      } catch (e, st) {
        ISpect.logger.handle(
          exception: e,
          stackTrace: st,
          message: 'Failed to access temporary directory for size calculation',
        );
      }

      // Handle application cache directory size calculation
      try {
        final appCacheDir = await getApplicationCacheDirectory();
        // Only calculate size if directory exists
        if (await appCacheDir.exists()) {
          futures.add(_getDirSize(appCacheDir));
        }
      } catch (e, st) {
        ISpect.logger.handle(
          exception: e,
          stackTrace: st,
          message: 'Failed to access app cache directory for size calculation',
        );
      }

      // Return 0 if no directories were accessible
      if (futures.isEmpty) return 0.0;

      // Wait for all size calculations to complete and sum the results
      final sizes = await Future.wait(futures);
      return sizes.fold<double>(0, (sum, size) => sum + size);
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to get cache size',
      );
      return 0.0;
    }
  }

  /// Calculates the size of a directory recursively
  ///
  /// Performs a deep scan of the directory structure to calculate total size by:
  /// - Recursively traversing all subdirectories
  /// - Validating each file before size calculation
  /// - Safely handling permission errors and inaccessible files
  /// - Avoiding following symbolic links to prevent infinite loops
  ///
  /// Parameters:
  /// - [dir]: The directory to calculate size for
  ///
  /// Returns: Total size in bytes, or 0.0 if calculation fails
  Future<double> _getDirSize(Directory dir) async {
    var size = 0.0;
    try {
      // Stream through all entities recursively, avoiding symlink loops
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        // Only process actual files (not directories or links)
        if (entity is File) {
          // Validate file before attempting to read its size
          final isValid = _isValidFileSync(entity);
          if (isValid) {
            try {
              // Add file size to running total
              size += await entity.length();
            } catch (e) {
              ISpect.logger.handle(
                exception: e,
                stackTrace: StackTrace.current,
                message: 'Failed to get file size: ${entity.path}',
              );
            }
          }
        }
      }
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to calculate directory size: ${dir.path}',
      );
    }
    return size;
  }

  /// Formats bytes into human-readable string (MB/GB)
  ///
  /// Converts raw byte values into user-friendly display format using binary units.
  /// - Values < 1GB are displayed in MB with 2 decimal places
  /// - Values >= 1GB are displayed in GB with 2 decimal places
  /// - Uses binary calculation (1024-based) for accuracy with file systems
  ///
  /// Parameters:
  /// - [sizeInBytes]: The size value in bytes to format
  ///
  /// Returns: Formatted string with appropriate unit suffix
  ///
  /// Examples:
  /// - formatSize(1048576) returns "1.00 MB"
  /// - formatSize(1073741824) returns "1.00 GB"
  @override
  String formatSize(double sizeInBytes) {
    // Define binary unit constants for accurate file system calculations
    const oneMB = 1024 * 1024;
    const oneGB = 1024 * oneMB;

    // Use GB for larger values to avoid unwieldy MB numbers
    if (sizeInBytes >= oneGB) {
      return '${(sizeInBytes / oneGB).toStringAsFixed(2)} GB';
    }

    // Default to MB for smaller values (including values < 1MB)
    return '${(sizeInBytes / oneMB).toStringAsFixed(2)} MB';
  }

  /// Validates whether a file is suitable for cache operations
  ///
  /// Applies comprehensive validation criteria to determine if a file should
  /// be included in cache operations (size calculation, deletion, etc.).
  ///
  /// Validation criteria:
  /// - File must exist on the file system
  /// - Must be a regular file (not a directory or special file)
  /// - Must have a valid file extension (not empty)
  ///
  /// Parameters:
  /// - [file]: The file to validate
  bool _isValidFileSync(File file) =>
      file.existsSync() &&
      !FileSystemEntity.isDirectorySync(file.path) &&
      p.extension(file.path).isNotEmpty;
}
