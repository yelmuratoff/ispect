import 'dart:io';

abstract class BaseFileService {
  Future<void> deleteCacheDir();
  Future<void> deleteAppDir();
  Future<List<File>> getFiles();
}
