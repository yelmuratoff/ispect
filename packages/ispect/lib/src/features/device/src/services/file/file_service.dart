import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class BaseFileService {
  Future<void> deleteCacheDir();
  Future<void> deleteAppDir();
  Future<List<File>> getFiles();
}

class AppFileService implements BaseFileService {
  const AppFileService._();

  static const BaseFileService _service = AppFileService._();
  static BaseFileService get instance => _service;

  @override
  Future<void> deleteAppDir() => _deleteAppDir();

  Future<void> _deleteAppDir() async {
    final appDir = await getApplicationSupportDirectory();

    if (appDir.existsSync()) {
      appDir.deleteSync(recursive: true);
    }
  }

  @override
  Future<void> deleteCacheDir() => _deleteCacheDir();

  Future<void> _deleteCacheDir() async {
    final cacheDir = await getTemporaryDirectory();

    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  }

  @override
  Future<List<File>> getFiles() => _getFilesList();

  Future<List<File>> _getFilesList() async {
    final fileModels = <File>[];
    final cacheDir = await getTemporaryDirectory();
    final files = cacheDir.listSync();
    for (final file in files) {
      final fileModel = File(file.path);
      final isValid = await isValidFile(fileModel);
      if (isValid) {
        fileModels.add(fileModel);
      }
    }
    return fileModels;
  }
}

Future<bool> isValidFile(FileSystemEntity entity) async {
  if (entity is! File) return false;
  final file = entity;
  final exists = await file.exists();
  final isDir = await FileSystemEntity.isDirectory(file.path);

  return exists && !isDir && p.extension(file.path).isNotEmpty;
}
