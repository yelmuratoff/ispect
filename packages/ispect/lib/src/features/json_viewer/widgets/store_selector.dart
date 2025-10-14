import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/json_viewer/widgets/controller/store.dart';

typedef JsonStoreSelectorBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

typedef JsonStoreSelectorComparator<T> = bool Function(T previous, T next);

/// Lightweight selector widget that listens to [JsonExplorerStore]
/// and rebuilds only when the selected value changes.
class JsonStoreSelector<T> extends StatefulWidget {
  const JsonStoreSelector({
    required this.store,
    required this.selector,
    required this.builder,
    this.shouldRebuild,
    super.key,
  });

  final JsonExplorerStore store;
  final T Function(JsonExplorerStore store) selector;
  final JsonStoreSelectorBuilder<T> builder;
  final JsonStoreSelectorComparator<T>? shouldRebuild;

  @override
  State<JsonStoreSelector<T>> createState() => _JsonStoreSelectorState<T>();
}

class _JsonStoreSelectorState<T> extends State<JsonStoreSelector<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.selector(widget.store);
    widget.store.addListener(_handleStoreChanged);
  }

  @override
  void didUpdateWidget(JsonStoreSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_handleStoreChanged);
      final newValue = widget.selector(widget.store);
      if (_shouldRebuild(_value, newValue)) {
        setState(() => _value = newValue);
      } else {
        _value = newValue;
      }
      widget.store.addListener(_handleStoreChanged);
    } else {
      final newValue = widget.selector(widget.store);
      if (_shouldRebuild(_value, newValue)) {
        setState(() => _value = newValue);
      }
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_handleStoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);

  void _handleStoreChanged() {
    final newValue = widget.selector(widget.store);
    if (_shouldRebuild(_value, newValue)) {
      setState(() {
        _value = newValue;
      });
    }
  }

  bool _shouldRebuild(T previous, T next) =>
      widget.shouldRebuild?.call(previous, next) ?? previous != next;
}
