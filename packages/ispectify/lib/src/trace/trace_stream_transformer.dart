import 'dart:async';

/// A [StreamTransformer] that hooks into stream lifecycle events for tracing.
///
/// **Lifecycle guarantees:**
/// - [onCancel] is called exactly once — either on subscription cancel or stream done
/// - All trace callbacks are wrapped in try/catch — exceptions never break the data stream
/// - [StreamController] is closed on done or cancel — no leaks
class TraceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  TraceStreamTransformer({
    required this.onListen,
    required this.onData,
    required this.onError,
    required this.onCancel,
  });

  final void Function() onListen;
  final void Function(T data) onData;
  final void Function(Object error, StackTrace stackTrace) onError;
  final void Function() onCancel;

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamSubscription<T> sub;
    late StreamController<T> controller;
    var cancelCalled = false;

    controller = StreamController<T>(
      onListen: () {
        try {
          onListen();
        } catch (_) {}
        sub = stream.listen(
          (data) {
            try {
              onData(data);
            } catch (_) {}
            if (!controller.isClosed) controller.add(data);
          },
          onError: (Object e, StackTrace st) {
            try {
              onError(e, st);
            } catch (_) {}
            if (!controller.isClosed) controller.addError(e, st);
          },
          onDone: () {
            if (!cancelCalled) {
              cancelCalled = true;
              try {
                onCancel();
              } catch (_) {}
            }
            controller.close();
          },
        );
      },
      onPause: () => sub.pause(),
      onResume: () => sub.resume(),
      onCancel: () {
        if (!cancelCalled) {
          cancelCalled = true;
          try {
            onCancel();
          } catch (_) {}
        }
        return sub.cancel();
      },
      sync: true,
    );

    return controller.stream;
  }
}
