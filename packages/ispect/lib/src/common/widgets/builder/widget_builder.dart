import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
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

  @override
  Widget build(BuildContext context) => StreamBuilder<ISpectLogData>(
        stream: widget.logger.stream,
        builder: (context, snapshot) {
          // Always get fresh data from logger history
          // StreamBuilder rebuilds when stream emits, so we always have latest data
          final currentData = widget.logger.history;

          // Invalidate cache if data length changed
          if (currentData.length != _lastDataLength) {
            _lastDataLength = currentData.length;
            widget.controller?.onDataChanged();
          }

          return widget.builder(context, currentData);
        },
      );
}
