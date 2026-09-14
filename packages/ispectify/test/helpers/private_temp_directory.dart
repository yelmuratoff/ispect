import 'dart:io';

import 'package:test/test.dart';

/// Creates a temporary directory restricted to the current user.
///
/// On Linux, Dart SDKs before dart-lang/sdk@c9546bfb21 create temp directories
/// with the process umask instead of `0700`.
Future<Directory> createPrivateTempDirectory(String prefix) async {
  final directory = await Directory.systemTemp.createTemp(prefix);
  if (!Platform.isWindows) {
    final chmod = await Process.run('chmod', ['0700', directory.path]);
    expect(chmod.exitCode, 0);
  }
  return directory;
}
