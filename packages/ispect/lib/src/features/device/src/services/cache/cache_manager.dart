import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/device/src/services/file/file_service.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class BaseCacheService {
  /// Deletes all cache directories and clears image cache
  Future<void> deleteCacheDir();

  /// Returns the total cache size in bytes
  Future<double> getCacheSize();

  /// Formats the size in bytes into a human-readable string (MB/GB)
  String formatSize(double sizeInBytes);
}

final class AppCacheManager implements BaseCacheService {
  const AppCacheManager();

  @override
  Future<void> deleteCacheDir() async {
    try {
      // Process directory deletions in parallel for better performance
      await Future.wait([
        _deleteMainCacheDirectories(),
        _deleteAndroidExternalDirectories(),
        _clearImageCache(),
      ]);

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
  Future<void> _deleteMainCacheDirectories() async {
    final futures = <Future<void>>[];

    try {
      final cacheDir = await getTemporaryDirectory();
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

    try {
      final appCacheDir = await getApplicationCacheDirectory();
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

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Deletes Android external cache directories if on Android platform
  Future<void> _deleteAndroidExternalDirectories() async {
    if (!Platform.isAndroid) return;

    try {
      final externalDirs = await getExternalCacheDirectories();
      if (externalDirs == null || externalDirs.isEmpty) return;

      final futures = externalDirs
          .map((dir) => _deleteSingleDirectory(dir, 'externalDir'))
          .toList();

      await Future.wait(futures);
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to access external cache directories',
      );
    }
  }

  /// Deletes a single directory with error handling
  Future<void> _deleteSingleDirectory(Directory dir, String dirType) async {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
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

  /// Clears Flutter's image cache
  Future<void> _clearImageCache() async {
    try {
      final imageCache = PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();

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

      // Calculate directory sizes in parallel
      try {
        final cacheDir = await getTemporaryDirectory();
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

      try {
        final appCacheDir = await getApplicationCacheDirectory();
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

      if (futures.isEmpty) return 0.0;

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
  Future<double> _getDirSize(Directory dir) async {
    var size = 0.0;
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final isValid = await isValidFile(entity);
          if (isValid) {
            try {
              size += await entity.length();
            } catch (e) {
              // Skip files that can't be read (permissions, etc.)
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
  /// Returns size in MB for values < 1GB, otherwise in GB
  /// Uses 1024-based calculation (binary)
  @override
  String formatSize(double sizeInBytes) {
    const oneMB = 1024 * 1024;
    const oneGB = 1024 * oneMB;

    if (sizeInBytes >= oneGB) {
      return '${(sizeInBytes / oneGB).toStringAsFixed(2)} GB';
    }
    return '${(sizeInBytes / oneMB).toStringAsFixed(2)} MB';
  }
}
