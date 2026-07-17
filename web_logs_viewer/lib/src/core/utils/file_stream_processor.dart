import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Maximum allowed file size: 100 MB.
const _maxFileSize = 100 * 1024 * 1024;

final class FileSizeLimitException implements Exception {
  const FileSizeLimitException({
    required this.maxFileSize,
    required this.actualSize,
  });

  final int maxFileSize;
  final int actualSize;

  @override
  String toString() =>
      'FileSizeLimitException(maxFileSize: $maxFileSize, '
      'actualSize: $actualSize)';
}

/// Processes a file stream and decodes its content.
StreamSubscription<Uint8List> processFileStream(
  dynamic file, {
  required void Function(String content) onSuccess,
  required void Function(Object error) onError,
  int maxFileSize = _maxFileSize,
}) {
  final stream = file.getStream() as Stream<Uint8List>;
  final chunks = <Uint8List>[];
  var totalSize = 0;
  var cancelled = false;

  late final StreamSubscription<Uint8List> subscription;
  subscription = stream.listen(
    (chunk) {
      totalSize += chunk.length;
      if (totalSize > maxFileSize) {
        cancelled = true;
        unawaited(subscription.cancel());
        onError(
          FileSizeLimitException(
            maxFileSize: maxFileSize,
            actualSize: totalSize,
          ),
        );
        return;
      }
      chunks.add(chunk);
    },
    onDone: () {
      if (cancelled) return;
      try {
        final combinedData = combineChunks(chunks);
        final content = utf8.decode(combinedData);
        onSuccess(content);
      } catch (e) {
        onError(e);
      }
    },
    onError: (Object error) {
      cancelled = true;
      onError(error);
    },
    cancelOnError: true,
  );

  return subscription;
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
