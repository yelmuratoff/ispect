import 'dart:io';

abstract interface class BaseCacheService {
  Future<void> deleteCacheDir({
    required bool isAndroid,
  });
  Future<List<File>> getFiles();
  Future<double> getCacheSize();
}
