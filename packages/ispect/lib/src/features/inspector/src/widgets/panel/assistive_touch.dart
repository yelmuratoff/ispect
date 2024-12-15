// ignore_for_file: avoid_positional_boolean_parameters, avoid_empty_blocks, avoid_unused_parameters, prefer_library_prefixes

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

@immutable
class AssistiveTouch extends StatefulWidget {
  const AssistiveTouch({
    super.key,
    this.child = const _DefaultChild(),
    this.visible = true,
    this.draggable = true,
    this.shouldStickToSide = true,
    this.margin = const EdgeInsets.all(8),
    this.initialOffset = Offset.infinite,
    this.onTap,
    this.animatedBuilder,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// Switches between showing the [child] or hiding it.
  final bool visible;

  /// Whether it can be dragged.
  final bool draggable;

  /// Whether it sticks to the side.
  final bool shouldStickToSide;

  /// Empty space to surround the [child].
  final EdgeInsets margin;

  /// Initial position.
  ///
  /// For example, if you want to put Assistive Touch to left-bottom cornor:
  ///
  /// ```dart
  /// AssistiveTouch(
  ///   initialOffset: const Offset(double.infinity, 0);
  ///   ...
  /// )
  /// ```
  final Offset initialOffset;

  /// A tap with a primary button has occurred.
  final VoidCallback? onTap;

  /// Custom animated builder.
  final Widget Function(
    BuildContext context,
    Widget child,
    bool visible,
  )? animatedBuilder;

  @override
  _AssistiveTouchState createState() => _AssistiveTouchState();
}

class _AssistiveTouchState extends State<AssistiveTouch>
    with TickerProviderStateMixin {
  bool _isInitialized = false;
  late Offset _offset = widget.initialOffset;
  late Offset _largerOffset = _offset;
  Size _size = Size.zero;
  bool _isDragging = false;
  bool _isIdle = true;
  Timer? _timer;
  late final AnimationController _scaleAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..addListener(() {
          setState(() {});
        });
  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _scaleAnimationController,
    curve: Curves.easeInOut,
  );
  Timer? _scaleTimer;

  @override
  void initState() {
    super.initState();
    _scaleTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!mounted) {
        return;
      }

      if (widget.visible) {
        _scaleAnimationController.forward();
      } else {
        _scaleAnimationController.reverse();
      }
    });
    FocusManager.instance.addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _setOffset(_offset);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleTimer?.cancel();
    _scaleAnimationController.dispose();
    FocusManager.instance.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _largerOffset = Offset(
        max(_largerOffset.dx, _offset.dx),
        max(_largerOffset.dy, _offset.dy),
      );

      _setOffset(_largerOffset, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;

    child = _MyMeasuredSize(
      child: child,
      onTapOutside: () {
        setState(() {
          _isIdle = true;
        });
      },
      onChange: (size) {
        setState(() {
          _size = size;
        });
        _setOffset(_offset);
      },
    );

    child = widget.draggable
        ? Draggable(
            onDragStarted: _onDragStart,
            onDragUpdate: _onDragUpdate,
            onDragEnd: _onDragEnd,
            feedback: child,
            child: child,
          )
        : child;

    child = GestureDetector(
      onTap: _onTap,
      child: child,
    );

    child = widget.animatedBuilder != null
        ? widget.animatedBuilder!(context, child, widget.visible)
        : ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedOpacity(
              opacity: _isIdle ? .3 : 1,
              duration: const Duration(milliseconds: 300),
              child: child,
            ),
          );

    child = Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: child,
    );

    return child;
  }

  void _onTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      setState(() {
        _isIdle = false;
      });
      _scheduleIdle();
    }
  }

  void _onDragStart() {
    setState(() {
      _isDragging = true;
      _isIdle = false;
    });
    _timer?.cancel();
  }

  void _onDragUpdate(DragUpdateDetails detail) {
    _setOffset(
      Offset(
        _offset.dx + detail.delta.dx,
        _offset.dy + detail.delta.dy,
      ),
    );
  }

  void _onDragEnd(DraggableDetails detail) {
    setState(() {
      _isDragging = false;
    });
    _scheduleIdle();

    _setOffset(_offset);
  }

  void _scheduleIdle() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!_isDragging) {
        setState(() {
          _isIdle = true;
        });
      }
    });
  }

  void _setOffset(Offset offset, [bool shouldUpdateLargerOffset = true]) {
    if (shouldUpdateLargerOffset) {
      _largerOffset = offset;
    }

    if (_isDragging) {
      setState(() {
        _offset = offset;
      });

      return;
    }

    final screenSize = MediaQuery.sizeOf(context);
    final screenPadding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final left = screenPadding.left + viewInsets.left + widget.margin.left;
    final top = screenPadding.top + viewInsets.top + widget.margin.top;
    final right = screenSize.width -
        screenPadding.right -
        viewInsets.right -
        widget.margin.right -
        _size.width;
    final bottom = screenSize.height -
        screenPadding.bottom -
        viewInsets.bottom -
        widget.margin.bottom -
        _size.height;

    final halfWidth = (right - left) / 2;

    if (widget.shouldStickToSide) {
      final normalizedTop = max(min(offset.dy, bottom), top);
      final normalizedLeft = max(
        min(
          normalizedTop == bottom || normalizedTop == top
              ? offset.dx
              : offset.dx < halfWidth
                  ? left
                  : right,
          right,
        ),
        left,
      );
      setState(() {
        _offset = Offset(normalizedLeft, normalizedTop);
      });
    } else {
      final normalizedTop = max(min(offset.dy, bottom), top);
      final normalizedLeft = max(min(offset.dx, right), left);
      setState(() {
        _offset = Offset(normalizedLeft, normalizedTop);
      });
    }
  }
}

class _MyMeasuredSize extends StatefulWidget {
  const _MyMeasuredSize({
    required this.onChange,
    required this.child,
    required this.onTapOutside,
  });

  final Widget child;

  final void Function(Size size) onChange;

  final VoidCallback? onTapOutside;

  @override
  _MyMeasuredSizeState createState() => _MyMeasuredSizeState();
}

class _MyMeasuredSizeState extends State<_MyMeasuredSize> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
    return TapRegion(
      onTapOutside: (_) {
        if (widget.onTapOutside != null) {
          widget.onTapOutside!.call();
        }
      },
      child: Container(
        key: _widgetKey,
        child: widget.child,
      ),
    );
  }

  final _widgetKey = GlobalKey();
  Size? _oldSize;

  Future<void> _postFrameCallback(Duration _) async {
    final context = _widgetKey.currentContext!;

    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );
    if (!context.mounted) return;

    final newSize = context.size!;
    if (newSize == Size.zero) return;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    widget.onChange(newSize);
  }
}

class _DefaultChild extends StatelessWidget {
  const _DefaultChild();

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        width: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.all(Radius.circular(28)),
        ),
        child: Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[400]!.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.all(Radius.circular(28)),
          ),
          child: Container(
            height: 32,
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[300]!.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.all(Radius.circular(28)),
            ),
            child: Container(
              height: 24,
              width: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
}
