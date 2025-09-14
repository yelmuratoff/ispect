import 'dart:async';

class StreamService {
  Timer? _timer;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  void start({
    required int intervalMs,
    required void Function() onTick,
    required bool Function() isMounted,
  }) {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!isMounted()) {
        stop();
        return;
      }
      onTick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void updateInterval(
      int newIntervalMs, void Function() onTick, bool Function() isMounted) {
    if (_isRunning) {
      stop();
      start(intervalMs: newIntervalMs, onTick: onTick, isMounted: isMounted);
    }
  }
}
