import 'package:flutter/widgets.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:ispect/src/ispect.dart';

/// Rebuilds [builder] only when the value returned by [selector] changes.
///
/// Subscribes to the nearest [ISpectScopeModel] (resolved via [ISpect.read])
/// and caches the previously selected value. The builder runs again only if
/// the new selection is unequal to the cached one, giving granular ribuilds
/// without leaking the full scope into the widget tree.
///
/// Throws [ISpectScopeNotFoundError] when used outside an `ISpectBuilder`
/// subtree.
class ISpectSelector<T> extends StatefulWidget {
  const ISpectSelector({
    required this.selector,
    required this.builder,
    super.key,
    this.child,
  });

  /// Projects the slice of [ISpectScopeModel] this widget cares about.
  final T Function(ISpectScopeModel scope) selector;

  /// Builds UI from the selected value. The optional [child] is forwarded
  /// unchanged so callers can hoist non-reactive subtrees out of rebuilds.
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// Subtree that does not depend on the selected value.
  final Widget? child;

  @override
  State<ISpectSelector<T>> createState() => _ISpectSelectorState<T>();
}

class _ISpectSelectorState<T> extends State<ISpectSelector<T>> {
  ISpectScopeModel? _scope;
  late T _value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ISpect.read(context);
    if (!identical(_scope, next)) {
      _scope?.removeListener(_onScopeChanged);
      _scope = next..addListener(_onScopeChanged);
      _value = widget.selector(next);
    }
  }

  @override
  void didUpdateWidget(covariant ISpectSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selector != widget.selector && _scope != null) {
      _value = widget.selector(_scope!);
    }
  }

  @override
  void dispose() {
    _scope?.removeListener(_onScopeChanged);
    super.dispose();
  }

  void _onScopeChanged() {
    final next = widget.selector(_scope!);
    if (next != _value) {
      setState(() => _value = next);
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, widget.child);
}
