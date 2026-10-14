import 'dart:async';
import 'dart:typed_data';

import 'file_stream_processor.dart';

/// Tracks in-flight file reads so they can be cancelled together.
final class FileReadTracker {
  final Set<StreamSubscription<Uint8List>> _active = {};
  int _generation = 0;

  /// The number of reads that have neither finished nor been cancelled.
  int get activeReads => _active.length;

  /// Identifies the reads started since the last [cancelAll].
  int get generation => _generation;

  /// Whether no [cancelAll] happened since [generation] was read.
  bool isCurrent(int generation) => generation == _generation;

  /// Streams [file] through [processFileStream] until it finishes, fails, or
  /// [cancelAll] runs; after a cancel neither callback fires.
  ///
  /// A failure thrown or returned by [onSuccess] is reported to [onError].
  void read(
    dynamic file, {
    required FutureOr<void> Function(String content) onSuccess,
    required void Function(Object error) onError,
    int maxFileSize = maxLoadableFileSize,
  }) {
    late final StreamSubscription<Uint8List> subscription;
    subscription = processFileStream(
      file,
      maxFileSize: maxFileSize,
      onSuccess: (content) {
        _active.remove(subscription);
        unawaited(_deliver(content, onSuccess, onError));
      },
      onError: (error) {
        _active.remove(subscription);
        onError(error);
      },
    );
    _active.add(subscription);
  }

  Future<void> _deliver(
    String content,
    FutureOr<void> Function(String content) onSuccess,
    void Function(Object error) onError,
  ) async {
    try {
      await onSuccess(content);
    } on Object catch (error) {
      onError(error);
    }
  }

  /// Cancels every in-flight read and starts a new [generation].
  Future<void> cancelAll() {
    _generation++;
    final cancelled = _active.toList(growable: false);
    _active.clear();
    return Future.wait(cancelled.map((subscription) => subscription.cancel()));
  }
}
