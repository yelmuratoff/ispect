import 'package:ispect/src/core/platform/platform_directory_base.dart';

class _WebPlatformDirectoryProvider implements PlatformDirectoryProvider {
  const _WebPlatformDirectoryProvider();

  @override
  Future<Object> logsBaseDirectory() async =>
      throw UnsupportedError('logsBaseDirectory is not available on web');

  @override
  Future<Object> tempDirectory() async =>
      throw UnsupportedError('tempDirectory is not available on web');
}

const PlatformDirectoryProvider platformDirectoryProvider =
    _WebPlatformDirectoryProvider();
