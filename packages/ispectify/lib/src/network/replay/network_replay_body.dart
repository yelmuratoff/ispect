import 'package:ispectify/src/network/replay/composer_picked_file.dart';

/// Transport-agnostic body of a composed/replayed HTTP request.
///
/// Each variant maps cleanly onto both Dio and `http` adapters without leaking
/// either client's types into the core. A `null` body means the request has no
/// payload (e.g. a plain `GET`).
sealed class NetworkReplayBody {
  const NetworkReplayBody();
}

/// A JSON payload serialized with `Content-Type: application/json`.
///
/// [value] is the decoded structure (typically a `Map` or `List`) that the
/// adapter encodes, mirroring how the original client would.
final class JsonReplayBody extends NetworkReplayBody {
  const JsonReplayBody(this.value);

  final Object? value;
}

/// A raw text payload sent verbatim.
final class TextReplayBody extends NetworkReplayBody {
  const TextReplayBody(this.text, {this.contentType});

  final String text;

  /// Explicit `Content-Type`; falls back to the request headers when `null`.
  final String? contentType;
}

/// An `application/x-www-form-urlencoded` payload.
final class FormUrlEncodedReplayBody extends NetworkReplayBody {
  const FormUrlEncodedReplayBody(this.fields);

  final Map<String, String> fields;
}

/// A `multipart/form-data` payload combining text fields and file parts.
///
/// File bytes are not present in captured logs, so a request reconstructed from
/// history restores [fields] only; [files] are populated when the user attaches
/// them in the composer.
final class MultipartReplayBody extends NetworkReplayBody {
  const MultipartReplayBody({
    this.fields = const [],
    this.files = const [],
  });

  final List<MultipartReplayField> fields;
  final List<MultipartReplayFile> files;
}

/// A single text field of a [MultipartReplayBody]. Field names may repeat,
/// so parts are modeled as a list rather than a map.
final class MultipartReplayField {
  const MultipartReplayField(this.name, this.value);

  final String name;
  final String value;
}

/// A single file part of a [MultipartReplayBody].
final class MultipartReplayFile {
  const MultipartReplayFile({required this.field, required this.file});

  /// Form field name the file is attached to.
  final String field;
  final ComposerPickedFile file;
}
