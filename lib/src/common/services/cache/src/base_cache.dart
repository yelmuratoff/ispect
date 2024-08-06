abstract interface class BaseCacheService {
  Future<void> deleteCacheDir({
    required bool isAndroid,
  });
  Future<double> getCacheSize();
}
