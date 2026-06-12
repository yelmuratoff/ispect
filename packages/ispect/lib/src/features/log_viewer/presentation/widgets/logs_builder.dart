import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispectify/ispectify.dart';

typedef ISpectWidgetBuilder = Widget Function(
  BuildContext context,
  List<ISpectLogData> data,
);

/// Builder widget for ISpectLogger data streams.
class ISpectLogsBuilder extends StatefulWidget {
  const ISpectLogsBuilder({
    required this.logger,
    required this.builder,
    super.key,
    this.controller,
  });

  final ISpectLogger logger;
  final ISpectWidgetBuilder builder;
  final ISpectViewController? controller;

  @override
  State<ISpectLogsBuilder> createState() => _ISpectLogsBuilderState();
}

class _ISpectLogsBuilderState extends State<ISpectLogsBuilder> {
  int _lastDataLength = 0;
  List<ISpectLogData>? _lastSnapshot;
  ISpectObserverDisposer? _disposeObserver;
  bool _rebuildScheduled = false;

  @override
  void initState() {
    super.initState();
    _attach();
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(ISpectLogsBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logger != widget.logger) {
      _detach();
      _attach();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _detach();
    super.dispose();
  }

  void _attach() {
    _disposeObserver = widget.logger.observe(_LogsObserver(_scheduleRebuild));
  }

  void _detach() {
    _disposeObserver?.call();
    _disposeObserver = null;
  }

  // Logger observers fire only on new log emissions; history mutations such
  // as clearHistory surface via controller notifications. The default history
  // getter returns a snapshot whose identity changes only on mutation, so the
  // identical() guard skips rebuilds for purely UI-state notifications.
  void _onControllerChanged() {
    if (identical(widget.logger.history, _lastSnapshot)) return;
    _scheduleRebuild();
  }

  void _scheduleRebuild() {
    if (!mounted || _rebuildScheduled) return;
    _rebuildScheduled = true;
    // Schedule rebuild after the current frame to avoid setState during
    // build/layout/paint phases (e.g. when a Flutter error triggers a log).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (mounted) setState(() {});
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = widget.logger.history;
    _lastSnapshot = currentData;

    // Invalidate filter cache when data length changes
    if (currentData.length != _lastDataLength) {
      _lastDataLength = currentData.length;
      widget.controller?.onDataChanged();
    }

    return widget.builder(context, currentData);
  }
}

class _LogsObserver implements ISpectObserver {
  _LogsObserver(this._onLog);

  final VoidCallback _onLog;

  @override
  void onLog(ISpectLogData data) => _onLog();

  @override
  void onError(ISpectLogData data) => _onLog();

  @override
  void onException(ISpectLogData data) => _onLog();
}
