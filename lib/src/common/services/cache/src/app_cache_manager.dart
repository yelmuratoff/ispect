import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/services/cache/src/base_cache.dart';
import 'package:path_provider/path_provider.dart';

final class AppCacheManager implements BaseCacheService {
  @override
  Future<void> deleteCacheDir({
    required DefaultCacheManager cache,
    required bool isAndroid,
  }) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appDir = await getApplicationSupportDirectory();

      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
        ISpectTalker.info("Cleared: cacheDir: ${cacheDir.path}");
      }

      if (appDir.existsSync()) {
        await appDir.delete(recursive: true);
        ISpectTalker.info("Cleared: appDir: ${appDir.path}");
      }

      if (isAndroid) {
        final List<Directory>? list = await getExternalCacheDirectories();
        if (list != null) {
          for (final Directory dir in list) {
            if (dir.existsSync()) {
              await dir.delete(recursive: true);
              ISpectTalker.info("Cleared: ${dir.path}");
            }
          }
        }
      }

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      ISpectTalker.info(
        "Cleared: imageCache: ${PaintingBinding.instance.imageCache.currentSize}, clearLiveImages: ${PaintingBinding.instance.imageCache.liveImageCount}",
      );

      await cache.emptyCache();
    } on Exception catch (e, st) {
      ISpectTalker.handle(
        exception: e,
        stackTrace: st,
        message: "Failed to clear cache",
      );
    }
  }

  @override
  Future<double> getCacheSize() {
    throw UnimplementedError();
  }

  @override
  Future<List<File>> getFiles() {
    throw UnimplementedError();
  }
}
