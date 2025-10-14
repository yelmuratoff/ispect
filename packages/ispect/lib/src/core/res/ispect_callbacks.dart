import 'dart:async';

typedef ISpectShareCallback = Future<void> Function(ISpectShareRequest request);

typedef ISpectOpenFileCallback = Future<void> Function(String path);

typedef ISpectInfoProvider = FutureOr<Map<String, dynamic>> Function();

/// Describes content to pass into a custom share handler.
final class ISpectShareRequest {
  const ISpectShareRequest({
    this.subject,
    this.text,
    this.filePaths = const [],
  });

  final String? subject;
  final String? text;
  final List<String> filePaths;

  bool get hasFiles => filePaths.isNotEmpty;
}
