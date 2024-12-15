import 'dart:io';

abstract interface class BaseFileService {
  Future<void> deleteCacheDir();
  Future<void> deleteAppDir();
  Future<List<File>> getFiles();
}
