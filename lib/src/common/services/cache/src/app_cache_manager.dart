import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/services/cache/src/base_cache.dart';
import 'package:path_provider/path_provider.dart';

final class AppCacheManager implements BaseCacheService {
  @override
  Future<void> deleteCacheDir({
    required bool isAndroid,
  }) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appDir = await getApplicationSupportDirectory();
      final appCacheDir = await getApplicationCacheDirectory();

      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
        ISpect.info('Cleared: cacheDir: ${cacheDir.path}');
      }

      if (appDir.existsSync()) {
        await appDir.delete(recursive: true);
        ISpect.info('Cleared: appDir: ${appDir.path}');
      }

      if (appCacheDir.existsSync()) {
        await appCacheDir.delete(recursive: true);
        ISpect.info('Cleared: appCacheDir: ${appCacheDir.path}');
      }

      if (isAndroid) {
        final list = await getExternalCacheDirectories();
        if (list != null) {
          for (final dir in list) {
            if (dir.existsSync()) {
              await dir.delete(recursive: true);
              ISpect.info('Cleared: ${dir.path}');
            }
          }
        }
      }

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      ISpect.info(
        'Cleared: imageCache: ${PaintingBinding.instance.imageCache.currentSize}, clearLiveImages: ${PaintingBinding.instance.imageCache.liveImageCount}',
      );
    } on Exception catch (e, st) {
      ISpect.handle(
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
      final appDir = await getApplicationSupportDirectory();
      final appCacheDir = await getApplicationCacheDirectory();

      var size = 0.0;

      if (cacheDir.existsSync()) {
        size += await _getDirSize(cacheDir);
      }

      if (appDir.existsSync()) {
        size += await _getDirSize(appDir);
      }

      if (appCacheDir.existsSync()) {
        size += await _getDirSize(appCacheDir);
      }

      return size;
    } on Exception catch (e, st) {
      ISpect.handle(
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
      if (entity is File) {
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
