import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract interface class BaseCacheService {
  Future<void> deleteCacheDir({
    required DefaultCacheManager cache,
    required bool isAndroid,
  });
  Future<List<File>> getFiles();
  Future<double> getCacheSize();
}
