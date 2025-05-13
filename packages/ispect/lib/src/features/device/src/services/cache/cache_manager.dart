import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/device/src/services/cache/base.dart';
import 'package:ispect/src/features/device/src/services/file/file_service.dart';

import 'package:path_provider/path_provider.dart';

final class AppCacheManager implements BaseCacheService {
  @override
  Future<void> deleteCacheDir({
    required bool isAndroid,
  }) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appCacheDir = await getApplicationCacheDirectory();

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        ISpect.logger.info('Cleared: cacheDir: ${cacheDir.path}');
      }

      if (await appCacheDir.exists()) {
        await appCacheDir.delete(recursive: true);
        ISpect.logger.info('Cleared: appCacheDir: ${appCacheDir.path}');
      }

      if (isAndroid) {
        final externalDirs = await getExternalCacheDirectories();
        if (externalDirs != null) {
          for (final dir in externalDirs) {
            try {
              if (await dir.exists()) {
                await dir.delete(recursive: true);
                ISpect.logger.info('Cleared: ${dir.path}');
              }
            } catch (e, st) {
              ISpect.logger.handle(
                exception: e,
                stackTrace: st,
                message: 'Failed to delete external dir: ${dir.path}',
              );
            }
          }
        }
      }

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
        message: 'Failed to clear cache',
      );
    }
  }

  @override
  Future<double> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appCacheDir = await getApplicationCacheDirectory();

      double size = 0;

      if (await cacheDir.exists()) {
        size += await _getDirSize(cacheDir);
      }

      if (await appCacheDir.exists()) {
        size += await _getDirSize(appCacheDir);
      }

      return size;
    } catch (e, st) {
      ISpect.logger.handle(
        exception: e,
        stackTrace: st,
        message: 'Failed to get cache size',
      );
      return 0;
    }
  }

  Future<double> _getDirSize(Directory dir) async {
    var size = 0.0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      final isValid = await isValidFile(entity);
      if (entity is File && isValid) {
        size += await entity.length();
      }
    }
    return size;
  }

  String formatSize(double sizeInBytes) {
    const oneMB = 1024 * 1024;
    const oneGB = 1024 * oneMB;

    if (sizeInBytes >= oneGB) {
      return '${(sizeInBytes / oneGB).toStringAsFixed(2)} GB';
    } else {
      return '${(sizeInBytes / oneMB).toStringAsFixed(2)} MB';
    }
  }
}
