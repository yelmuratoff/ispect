import 'package:meta/meta.dart';

/// A file selected by the host application for a composed multipart request.
///
/// ISpect never reaches into the filesystem itself; the application supplies
/// the bytes through `ISpectOptions.onPickComposerFile`, so no file-picker
/// dependency leaks into the toolkit. Bytes (rather than a path) are carried so
/// the same value works on web and native.
@immutable
final class ComposerPickedFile {
  const ComposerPickedFile({
    required this.filename,
    required this.bytes,
    this.contentType,
  });

  /// File name advertised in the multipart part (e.g. `avatar.png`).
  final String filename;

  /// Raw file contents.
  final List<int> bytes;

  /// MIME type, when the picker can determine it (e.g. `image/png`).
  final String? contentType;
}
