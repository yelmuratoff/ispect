import 'dart:async';

import 'package:ispect/ispect.dart';
import 'package:material_ui/material_ui.dart';

/// Calls the ISpect service extension [method] with [args] on the debugged
/// app and returns its JSON body.
///
/// Throws [ISpectExtensionMissing] when the app does not register the
/// extension, and [ISpectCursorExpired] when `afterId` is no longer in the
/// app's history.
typedef ISpectServiceCall =
    Future<Map<String, Object?>> Function(
      String method,
      Map<String, String> args,
    );

/// The app answered without ISpect's service extensions, because it was
/// built without `ISPECT_ENABLED` or never initialized ISpect.
final class ISpectExtensionMissing implements Exception {
  const ISpectExtensionMissing();
}

/// The app no longer holds the entry the cursor points at, as after a hot
/// restart.
final class ISpectCursorExpired implements Exception {
  const ISpectCursorExpired();
}

enum ISpectVmLogStatus { connecting, live, notEnabled, outdated, unreachable }

/// Copies the debugged app's log history into [sink] and keeps it current.
///
/// The first page brings the newest [pageSize] entries; later polls page
/// forward from the last entry copied, so each entry is added once. When the
/// app restarts, [sink] is cleared and filled again.
final class ISpectVmLogSource {
  ISpectVmLogSource({
    required ISpectServiceCall call,
    required ISpectLogger sink,
    this.pageSize = 200,
  }) : _call = call,
       _sink = sink;

  /// The lowest `protocolVersion` whose `getLogs` returns full records.
  static const minimumProtocolVersion = 2;

  final ISpectServiceCall _call;
  final ISpectLogger _sink;
  final int pageSize;

  final ValueNotifier<ISpectVmLogStatus> status = ValueNotifier(
    ISpectVmLogStatus.connecting,
  );

  String? _cursor;
  bool _protocolChecked = false;
  bool _polling = false;
  bool _disposed = false;
  Timer? _timer;

  /// Polls now and then every [interval] until [dispose].
  void start({Duration interval = const Duration(seconds: 1)}) {
    unawaited(poll());
    _timer = Timer.periodic(interval, (_) => unawaited(poll()));
  }

  /// Fetches every entry logged since the last poll. Overlapping calls
  /// return at once, and a failed call only changes [status].
  Future<void> poll() async {
    if (_polling || _disposed) return;
    _polling = true;
    try {
      if (!_protocolChecked) await _checkProtocol();
      if (!_protocolChecked) return;
      await _pullNewEntries();
      _setStatus(ISpectVmLogStatus.live);
    } on ISpectExtensionMissing {
      _setStatus(ISpectVmLogStatus.notEnabled);
    } on ISpectCursorExpired {
      _cursor = null;
      _sink.clearHistory();
      _setStatus(ISpectVmLogStatus.live);
    } on Exception {
      _setStatus(ISpectVmLogStatus.unreachable);
    } finally {
      _polling = false;
    }
  }

  Future<void> _checkProtocol() async {
    final summary = await _call(ISpectServiceExtensions.getSummary, const {});
    final version = summary['protocolVersion'];
    if (version is int && version >= minimumProtocolVersion) {
      _protocolChecked = true;
    } else {
      _setStatus(ISpectVmLogStatus.outdated);
    }
  }

  Future<void> _pullNewEntries() async {
    var hasNewer = true;
    while (hasNewer) {
      final cursor = _cursor;
      final body = await _call(ISpectServiceExtensions.getLogs, {
        'detail': 'full',
        'limit': '$pageSize',
        'afterId': ?cursor,
      });
      for (final entry in (body['logs'] as List<Object?>?) ?? const []) {
        if (entry case {'id': final String id}) {
          _copy(entry);
          _cursor = id;
        }
      }
      _cursor = body['cursor'] as String? ?? _cursor;
      hasNewer = cursor != null && body['hasMore'] == true;
    }
  }

  void _copy(Map<Object?, Object?> entry) {
    if (entry case {'log': final Map<String, dynamic> record}) {
      try {
        _sink.logData(ISpectLogDataJsonUtils.fromJson(record));
      } on FormatException {
        return;
      }
    }
  }

  void _setStatus(ISpectVmLogStatus value) {
    if (!_disposed) status.value = value;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    status.dispose();
  }
}
