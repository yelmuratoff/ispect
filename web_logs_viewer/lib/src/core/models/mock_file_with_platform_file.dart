import 'package:file_picker/file_picker.dart';

class MockFileWithPlatformFile {
  const MockFileWithPlatformFile({
    required this.content,
    this.fileName,
    this.size,
    required this.platformFile,
  });

  final String content;
  final String? fileName;
  final int? size;
  final PlatformFile platformFile;

  int? get length => size;
}
