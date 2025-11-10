import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Processes a file stream and decodes its content.
StreamSubscription<Uint8List> processFileStream(
  dynamic file, {
  required void Function(String content) onSuccess,
  required void Function(Object error) onError,
}) {
  final stream = file.getStream();
  final chunks = <Uint8List>[];

  return stream.listen(
    chunks.add,
    onDone: () {
      try {
        final combinedData = combineChunks(chunks);
        final content = utf8.decode(combinedData);
        onSuccess(content);
      } catch (e) {
        onError(e);
      }
    },
    onError: onError,
  );
}

/// Combines multiple chunks into a single Uint8List.
Uint8List combineChunks(List<Uint8List> chunks) {
  final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
  final result = Uint8List(totalLength);
  var offset = 0;

  for (final chunk in chunks) {
    result.setRange(offset, offset + chunk.length, chunk);
    offset += chunk.length;
  }

  return result;
}
