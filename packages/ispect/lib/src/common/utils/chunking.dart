typedef ChunkHandler<T> = void Function(Iterable<T> chunk);

/// Utilities for consistent chunked/batched processing across the codebase.
class Chunking {
  /// Yields the input list in fixed-size chunks. The last chunk may be smaller.
  static Iterable<Iterable<T>> chunks<T>(List<T> list, int size) sync* {
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'must be positive');
    }
    for (var i = 0; i < list.length; i += size) {
      yield list.skip(i).take(size);
    }
  }

  /// Cooperatively yields to the event loop every [everyChunks] iterations.
  static Future<void> yieldEvery(int processedChunks, int everyChunks) async {
    if (everyChunks <= 0) return;
    if (processedChunks % everyChunks == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}
