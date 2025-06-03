import 'package:flutter/material.dart';
import 'package:ispectify/ispectify.dart';

typedef ISpectifyWidgetBuilder = Widget Function(
  BuildContext context,
  List<ISpectifyData> data,
);

/// Builder widget for ISpectify data streams.
class ISpectifyBuilder extends StatefulWidget {
  const ISpectifyBuilder({
    required this.iSpectify,
    required this.builder,
    super.key,
  });

  final ISpectify iSpectify;
  final ISpectifyWidgetBuilder builder;

  @override
  State<ISpectifyBuilder> createState() => _ISpectifyBuilderState();
}

class _ISpectifyBuilderState extends State<ISpectifyBuilder> {
  List<ISpectifyData>? _lastData;
  int _lastDataLength = 0;

  @override
  Widget build(BuildContext context) => StreamBuilder<ISpectifyData>(
        stream: widget.iSpectify.stream,
        builder: (context, snapshot) {
          final currentData = widget.iSpectify.history;

          if (_shouldRebuild(currentData)) {
            _lastData = List.from(currentData);
            _lastDataLength = currentData.length;
            return widget.builder(context, currentData);
          }

          // Return cached widget if data hasn't meaningfully changed
          return widget.builder(context, _lastData ?? currentData);
        },
      );

  /// Determines if the widget should rebuild based on data changes.
  bool _shouldRebuild(List<ISpectifyData> newData) {
    // Always rebuild if this is the first build
    if (_lastData == null) return true;

    // Rebuild if length changed
    if (newData.length != _lastDataLength) return true;

    // For performance, only check the most recent items for changes
    // This covers the common case of new logs being added
    const checkCount = 10;
    final itemsToCheck =
        newData.length < checkCount ? newData.length : checkCount;

    if (itemsToCheck > 0) {
      for (var i = 0; i < itemsToCheck; i++) {
        final newIndex = newData.length - 1 - i;
        final oldIndex = _lastData!.length - 1 - i;

        if (oldIndex < 0 ||
            newData[newIndex].hashCode != _lastData![oldIndex].hashCode) {
          return true;
        }
      }
    }

    return false;
  }
}
