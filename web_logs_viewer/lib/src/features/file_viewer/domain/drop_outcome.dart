import 'dart:typed_data';

/// What reading one dropped item produced.
sealed class DropOutcome {
  const DropOutcome();
}

/// A file whose content still has to be streamed.
final class DroppedFile extends DropOutcome {
  const DroppedFile({
    required this.fileName,
    required Stream<Uint8List> Function() openStream,
    this.displayName,
    this.mimeType,
  }) : _openStream = openStream;

  final String? fileName;
  final String? displayName;
  final String? mimeType;
  final Stream<Uint8List> Function() _openStream;

  /// Opens the stream of the file content.
  Stream<Uint8List> getStream() => _openStream();
}

/// The URI of a file that lives outside the browser sandbox.
final class DroppedFileUri extends DropOutcome {
  const DroppedFileUri(this.uri);

  final Uri uri;
}

/// Text the drop carried inline rather than as a file.
final class DroppedText extends DropOutcome {
  const DroppedText({
    required this.content,
    required this.fileName,
    required this.displayName,
    required this.mimeType,
  });

  final String content;
  final String fileName;
  final String displayName;
  final String mimeType;
}

/// A file URI that could not be read.
final class ExternalFileFailure extends DropOutcome {
  const ExternalFileFailure({required this.fileName, required this.error});

  final String fileName;
  final String error;
}

/// A drop format that could not be read.
final class DropFormatFailure extends DropOutcome {
  const DropFormatFailure({
    required this.type,
    required this.format,
    required this.error,
  });

  final String type;
  final String format;
  final String error;
}
