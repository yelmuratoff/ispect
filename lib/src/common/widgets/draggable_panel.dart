import 'package:flutter/material.dart';

//ignore: must_be_immutable
class DraggableButtonPanel extends StatefulWidget {
  DraggableButtonPanel({
    required this.options,
    required this.child,
    super.key,
    this.top = 50,
    this.left = 10,
    this.buttonSize = 55,
    this.panelColor = Colors.white,
    this.buttonColor = Colors.blue,
    this.collapseOpacity = 0.8,
  });

  final List<IconButton> options;
  final Widget child;
  final double buttonSize;
  final Color panelColor;
  final Color buttonColor;
  final double collapseOpacity;
  double top;
  double left;

  @override
  State<DraggableButtonPanel> createState() => DraggableButtonPanelState();
}

class DraggableButtonPanelState extends State<DraggableButtonPanel> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  bool _isLeftPositioned = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  late double _panelWidth;

  void _updatePosition(Offset newPosition) {
    if (newPosition != Offset(widget.left, widget.top)) {
      setState(() {
        widget
          ..left = newPosition.dx
          ..top = newPosition.dy;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final double childrenWidth = widget.options.fold(
      0.0,
      (double previousValue, IconButton iconButton) => previousValue + (iconButton.iconSize != null ? iconButton.iconSize! : 50.0),
    );

    _panelWidth = childrenWidth + widget.buttonSize + 30;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    if (_isOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _isOpen ? 1 : widget.collapseOpacity,
        duration: const Duration(milliseconds: 300),
        child: Draggable<int>(
          onDragEnd: _onDragEnd,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _buildFeedback(),
          child: _buildMainPanel(context),
        ),
      );

  void _onDragEnd(DraggableDetails draggableDetails) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final padding = MediaQuery.of(context).padding;

    final availableHeight = screenHeight - padding.top - padding.bottom - kToolbarHeight - kBottomNavigationBarHeight;
    final availableWidth = screenWidth - padding.left - padding.right;

    final newPosition = Offset(
      draggableDetails.offset.dx,
      draggableDetails.offset.dy - widget.buttonSize,
    );
    _updatePosition(newPosition);

    setState(() {
      final finalPosition = draggableDetails.offset.dy - widget.buttonSize;

      _isLeftPositioned = draggableDetails.offset.dx < availableWidth / 2;

      if (finalPosition < 50) {
        widget.top = 50;
      } else if (finalPosition + widget.buttonSize > availableHeight) {
        widget.top = availableHeight - widget.buttonSize - 50;
      } else {
        widget.top = finalPosition;
      }
    });
  }

  Widget _buildFeedback() => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
          color: widget.buttonColor,
        ),
        width: 56.0,
        height: 56.0,
        child: widget.options.length > 1
            ? const Icon(
                Icons.menu_open_rounded,
                color: Colors.white,
              )
            : widget.options.first.icon,
      );

  Widget _buildMainPanel(BuildContext context) {
    if (widget.options.length == 1) {
      setState(() {
        final IconButton firstButton = widget.options.first;
        widget.options.first = IconButton(
          icon: firstButton.icon,
          onPressed: firstButton.onPressed,
          color: Colors.white,
        );
      });
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Stack(
        children: [
          widget.child,
          if (widget.options.length > 1)
            Positioned(
              top: widget.top,
              left: _isLeftPositioned ? 0 : (MediaQuery.of(context).size.width - _panelWidth * _animation.value),
              child: Container(
                height: widget.buttonSize,
                width: _panelWidth * _animation.value,
                decoration: BoxDecoration(
                  color: widget.panelColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: _isLeftPositioned,
                  itemCount: widget.options.length,
                  itemBuilder: (BuildContext context, int index) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: widget.options[index],
                  ),
                ),
              ),
            ),
          Positioned(
            top: widget.top,
            left: _isLeftPositioned ? 0 : MediaQuery.of(context).size.width - widget.buttonSize,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: _isLeftPositioned
                    ? const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                color: widget.buttonColor,
              ),
              width: widget.buttonSize,
              height: widget.buttonSize,
              child: widget.options.length > 1
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 850),
                      child: _isOpen
                          ? RotatedBox(
                              quarterTurns: _isLeftPositioned ? 0 : 2,
                              child: IconButton(
                                icon: const Icon(Icons.menu_open_rounded),
                                color: Colors.white,
                                onPressed: _triggerAnimation,
                              ),
                            )
                          : RotatedBox(
                              quarterTurns: _isLeftPositioned ? 2 : 0,
                              child: IconButton(
                                icon: const Icon(Icons.menu_open_rounded),
                                color: Colors.white,
                                onPressed: _triggerAnimation,
                              ),
                            ),
                    )
                  : widget.options.first,
            ),
          ),
        ],
      ),
    );
  }
}
