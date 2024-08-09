// // ignore_for_file: avoid_empty_blocks, prefer_int_literals
// import 'dart:async';
// import 'dart:developer';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:ispect/src/common/widgets/circular_menu/item.dart';

// class DraggableCircularMenu extends StatefulWidget {
//   /// use global key to control animation anywhere in the code
//   final GlobalKey<DraggableCircularMenuState>? menuKey;

//   /// list of CircularMenuItem contains at least two items.
//   final List<CircularMenuItem> items;

//   /// menu alignment
//   final Alignment alignment;

//   /// menu radius
//   final double radius;

//   /// widget holds actual page content
//   final Widget child;

//   /// animation duration
//   final Duration animationDuration;
//   final Duration alignAnimationDuration;

//   /// animation curve in forward
//   final Curve curve;

//   /// animation curve in reverse
//   final Curve reverseCurve;

//   /// callback
//   final VoidCallback? toggleButtonOnPressed;
//   final Color toggleButtonColor;
//   final double toggleButtonSize;
//   final List<BoxShadow>? toggleButtonBoxShadow;
//   final double toggleButtonPadding;
//   final double toggleButtonMargin;
//   final Color? toggleButtonIconColor;
//   final AnimatedIconData toggleButtonAnimatedIconData;

//   /// starting angle in clockwise radian
//   final double? startingAngleInRadian;

//   /// ending angle in clockwise radian

//   final double? endingAngleInRadian;

//   /// should the menu be draggable
//   final bool isDraggable;

//   /// step size for dragging
//   final ({double x, double y}) stepSize;

//   DraggableCircularMenu({
//     required this.items,
//     this.alignment = Alignment.bottomCenter,
//     this.radius = 100,
//     required this.child,
//     this.animationDuration = const Duration(milliseconds: 500),
//     this.curve = Curves.bounceOut,
//     this.reverseCurve = Curves.fastOutSlowIn,
//     this.toggleButtonOnPressed,
//     required this.toggleButtonColor,
//     this.toggleButtonBoxShadow,
//     this.toggleButtonMargin = 10,
//     this.toggleButtonPadding = 10,
//     this.toggleButtonSize = 30,
//     this.toggleButtonIconColor,
//     this.toggleButtonAnimatedIconData = AnimatedIcons.menu_close,
//     this.menuKey,
//     this.startingAngleInRadian,
//     this.endingAngleInRadian,
//     this.alignAnimationDuration = Duration.zero,
//     this.isDraggable = false,
//     this.stepSize = (x: 0.1, y: 0.1),
//   })  : assert(items.isNotEmpty, 'items can not be empty list'),
//         assert(items.length > 1, 'if you have one item no need to use a Menu'),
//         assert(stepSize.x > 0 || stepSize.x < 1, 'stepSize.x must be between 0 and 1'),
//         assert(stepSize.y > 0 || stepSize.y < 1, 'stepSize.y must be between 0 and 1'),
//         super(key: menuKey);

//   @override
//   DraggableCircularMenuState createState() => DraggableCircularMenuState();
// }

// class DraggableCircularMenuState extends State<DraggableCircularMenu> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   double _completeAngle = 2 * math.pi;
//   double _initialAngle = 0;
//   late int _itemsCount;
//   late Animation<double> _animation;
//   Offset _buttonPosition = const Offset(0, 100);
//   Timer? _hideTimer;
//   Timer? _fullHideTimer;
//   bool _isFullyHidden = false;
//   bool _isGradding = false;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(vsync: this, duration: widget.animationDuration)
//       ..addListener(() {
//         setState(() {});
//       });
//     _animation = Tween(begin: 0.0, end: 1.0)
//         .animate(CurvedAnimation(parent: _animationController, curve: widget.curve, reverseCurve: widget.reverseCurve));
//     _itemsCount = widget.items.length;
//     _startHideTimers();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _hideTimer?.cancel();
//     _fullHideTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.sizeOf(context);
//     final alignment = _getAlignmentFromOffset(_buttonPosition, screenSize);

//     _configureAlignmentBasedAngles(alignment);

//     return GestureDetector(
//       onTap: () {
//         if (_animationController.isCompleted) {
//           _closeMenu();
//         }
//       },
//       child: Stack(
//         key: widget.menuKey,
//         children: <Widget>[
//           widget.child,
//           ..._buildMenuItems(
//             alignment,
//             screenSize: screenSize,
//           ),
//           _buildMenuButton(
//             context,
//             screenSize: screenSize,
//           ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildMenuItems(
//     Alignment alignment, {
//     required Size screenSize,
//   }) {
//     List<Widget> items = [];
//     final bool isInLeftSide = _isInLeftSide(screenSize);
//     final double rightPosition = screenSize.width - _buttonPosition.dx - widget.toggleButtonSize * 2;

//     widget.items.asMap().forEach((index, item) {
//       items.add(
//         Positioned(
//           left: isInLeftSide ? _buttonPosition.dx : null,
//           right: !isInLeftSide ? rightPosition : null,
//           top: _buttonPosition.dy,
//           child: Transform.translate(
//             offset: Offset.fromDirection(
//               _completeAngle == (2 * math.pi)
//                   ? (_initialAngle + (_completeAngle / (_itemsCount)) * index)
//                   : (_initialAngle + (_completeAngle / (_itemsCount - 1)) * index),
//               _animation.value * widget.radius,
//             ),
//             child: Transform.scale(
//               scale: _animation.value,
//               child: Transform.rotate(
//                 angle: _animation.value * (math.pi * 2),
//                 child: CircularMenuItemWidget(
//                   item: item,
//                   closeMenu: _closeMenu,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//     return items;
//   }

//   Widget _buildMenuButton(
//     BuildContext context, {
//     required Size screenSize,
//   }) {
//     final bool isInLeftSide = _isInLeftSide(screenSize);
//     final bool isInRightSide = _isInRightSide(screenSize);

//     final double rightPosition = screenSize.width - _buttonPosition.dx - widget.toggleButtonSize * 2;

//     return Positioned(
//       left: isInLeftSide ? _buttonPosition.dx : null,
//       right: !isInLeftSide ? rightPosition : null,
//       top: _buttonPosition.dy,
//       child: TapRegion(
//         onTapOutside: (_) {
//           if (_animationController.isCompleted) {
//             _closeMenu();
//           }
//         },
//         child: GestureDetector(
//           onPanUpdate: (details) {
//             setState(() {
//               _buttonPosition += details.delta;
//               _isGradding = true;
//               _buttonPosition = Offset(
//                 _buttonPosition.dx.clamp(0.0, screenSize.width - widget.toggleButtonSize * 2),
//                 _buttonPosition.dy.clamp(50, screenSize.height - 100),
//               );
//             });
//           },
//           onPanEnd: (details) {
//             setState(() {
//               if (_buttonPosition.dx > _halfScreenWidth(screenSize)) {
//                 _buttonPosition = Offset(screenSize.width - widget.toggleButtonSize * 2, _buttonPosition.dy);
//               } else {
//                 _buttonPosition = Offset(0, _buttonPosition.dy);
//               }
//               _isGradding = false;
//             });
//           },
//           child: Material(
//             color: Colors.transparent,
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               margin: const EdgeInsets.all(0),
//               width: _isFullyHidden ? 20 : widget.toggleButtonSize * 1.5,
//               height: 70,
//               decoration: BoxDecoration(
//                 color: _isFullyHidden ? widget.toggleButtonColor.withOpacity(0.3) : widget.toggleButtonColor,
//                 borderRadius: BorderRadius.only(
//                   topRight: isInLeftSide || _isGradding ? const Radius.circular(16) : Radius.zero,
//                   bottomRight: isInLeftSide || _isGradding ? const Radius.circular(16) : Radius.zero,
//                   topLeft: isInRightSide || _isGradding ? const Radius.circular(16) : Radius.zero,
//                   bottomLeft: isInRightSide || _isGradding ? const Radius.circular(16) : Radius.zero,
//                 ),
//               ),
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(16),
//                 onTap: () {
//                   _closeMenu();
//                   if (widget.toggleButtonOnPressed != null) {
//                     widget.toggleButtonOnPressed!();
//                   }
//                 },
//                 child: _isFullyHidden
//                     ? _isGradding
//                         ? const SizedBox()
//                         : Center(
//                             child: CustomPaint(
//                               willChange: true,
//                               size: const Size(20, 70),
//                               painter: LineWithCurvePainter(
//                                 isInRightSide: isInRightSide,
//                               ),
//                             ),
//                           )
//                     : Center(
//                         child: AnimatedIcon(
//                           icon: widget.toggleButtonAnimatedIconData,
//                           size: widget.toggleButtonSize,
//                           color: widget.toggleButtonIconColor ?? Colors.white,
//                           progress: _animation,
//                         ),
//                       ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   double _halfScreenWidth(Size screenSize) => (screenSize.width / 2 - widget.toggleButtonSize / 2);

//   bool _isInLeftSide(Size screenSize) => _buttonPosition.dx < _halfScreenWidth(screenSize);

//   bool _isInRightSide(Size screenSize) => _buttonPosition.dx > _halfScreenWidth(screenSize);

//   void _closeMenu() {
//     if (_animationController.status == AnimationStatus.dismissed) {
//       (_animationController).forward();
//       _resetHideTimers();
//     } else {
//       (_animationController).reverse();
//     }
//   }

//   void _startHideTimers() {
//     _hideTimer = Timer(const Duration(seconds: 3), () {
//       log('Status: ${_animationController.status}');
//       if (_animationController.status == AnimationStatus.completed) {
//         _closeMenu();
//       }
//     });
//     _fullHideTimer = Timer(const Duration(seconds: 4), () {
//       if (_animationController.status == AnimationStatus.dismissed) {
//         setState(() {
//           _isFullyHidden = true;
//         });
//       }
//     });
//   }

//   void _resetHideTimers() {
//     _hideTimer?.cancel();
//     _fullHideTimer?.cancel();
//     setState(() {
//       _isFullyHidden = false;
//     });
//     _startHideTimers();
//   }

//   Alignment _getAlignmentFromOffset(Offset offset, Size containerSize) {
//     double normalizedX = (offset.dx / containerSize.width) * 2 - 1;
//     double normalizedY = (offset.dy / containerSize.height) * 2 - 1;

//     if (normalizedX < -0.5 && normalizedY < -0.5) {
//       return Alignment.topLeft;
//     } else if (normalizedX > 0.5 && normalizedY < -0.5) {
//       return Alignment.topRight;
//     } else if (normalizedX < -0.5 && normalizedY > 0.5) {
//       return Alignment.bottomLeft;
//     } else if (normalizedX > 0.5 && normalizedY > 0.5) {
//       return Alignment.bottomRight;
//     } else if (normalizedX < -0.5) {
//       return Alignment.centerLeft;
//     } else if (normalizedX > 0.5) {
//       return Alignment.centerRight;
//     } else if (normalizedY < -0.5) {
//       return Alignment.topCenter;
//     } else if (normalizedY > 0.5) {
//       return Alignment.bottomCenter;
//     } else {
//       return Alignment.center;
//     }
//   }

//   void _configureAlignmentBasedAngles(Alignment alignment) {
//     switch (alignment) {
//       case Alignment.bottomCenter:
//         _completeAngle = 1 * math.pi;
//         _initialAngle = 1 * math.pi;
//         break;
//       case Alignment.topCenter:
//         _completeAngle = 1 * math.pi;
//         _initialAngle = 0 * math.pi;
//         break;
//       case Alignment.centerLeft:
//         _completeAngle = 1 * math.pi;
//         _initialAngle = 1.5 * math.pi;
//         break;
//       case Alignment.centerRight:
//         _completeAngle = 1 * math.pi;
//         _initialAngle = 0.5 * math.pi;
//         break;
//       case Alignment.center:
//         _completeAngle = 2 * math.pi;
//         _initialAngle = 0 * math.pi;
//         break;
//       case Alignment.bottomRight:
//         _completeAngle = 0.5 * math.pi;
//         _initialAngle = 1 * math.pi;
//         break;
//       case Alignment.bottomLeft:
//         _completeAngle = 0.5 * math.pi;
//         _initialAngle = 1.5 * math.pi;
//         break;
//       case Alignment.topLeft:
//         _completeAngle = 0.5 * math.pi;
//         _initialAngle = 0 * math.pi;
//         break;
//       case Alignment.topRight:
//         _completeAngle = 0.5 * math.pi;
//         _initialAngle = 0.5 * math.pi;
//         break;
//       default:
//         throw 'Alignment not supported';
//     }
//   }
// }

// class LineWithCurvePainter extends CustomPainter {
//   final bool isInRightSide;

//   LineWithCurvePainter({required this.isInRightSide});

//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..color = Colors.white.withOpacity(0.4)
//       ..strokeWidth = 5
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round;

//     double startX = isInRightSide ? size.width - 8 : 8;
//     double controlPointX = size.width / 2;
//     double endX = size.width / 2 + (isInRightSide ? 2 : -2);

//     Path path = Path()
//       ..moveTo(startX, 14)
//       ..quadraticBezierTo(
//         controlPointX,
//         size.height / 2,
//         endX,
//         size.height - 14,
//       );

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }
