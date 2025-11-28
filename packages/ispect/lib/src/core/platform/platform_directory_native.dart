import 'package:flutter/foundation.dart';
import 'package:ispect/src/core/platform/platform_directory_base.dart';
import 'package:path_provider/path_provider.dart';

class DefaultPlatformDirectoryProvider implements PlatformDirectoryProvider {
  const DefaultPlatformDirectoryProvider();

  @override
  Future<Object> logsBaseDirectory() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return getApplicationDocumentsDirectory();
      default:
        return getTemporaryDirectory();
    }
  }

  @override
  Future<Object> tempDirectory() => getTemporaryDirectory();
}

const PlatformDirectoryProvider platformDirectoryProvider =
    DefaultPlatformDirectoryProvider();
