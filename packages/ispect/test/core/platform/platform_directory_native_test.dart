import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/core/platform/platform_directory_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolves the application cache directory path for file history',
      () async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var methodName = '';
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    messenger.setMockMethodCallHandler(channel, (method) async {
      methodName = method.method;
      return Directory.systemTemp.path;
    });

    final path =
        await const DefaultPlatformDirectoryProvider().cacheDirectoryPath();

    expect(methodName, 'getApplicationCacheDirectory');
    expect(path, Directory.systemTemp.path);
  });
}
