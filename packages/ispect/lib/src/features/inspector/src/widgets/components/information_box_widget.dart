import 'package:flutter/material.dart';

class InformationBoxWidget extends StatelessWidget {
  const InformationBoxWidget({
    required this.child,
    super.key,
    this.color,
  });

  factory InformationBoxWidget.size({
    required Size size,
    Key? key,
    Color? color,
  }) =>
      InformationBoxWidget(
        key: key,
        color: color,
        child: Text(
          '${size.width.toStringAsFixed(1)} × ${size.height.toStringAsFixed(1)}',
        ),
      );

  factory InformationBoxWidget.number({
    required double number,
    Key? key,
    Color? color,
  }) =>
      InformationBoxWidget(
        key: key,
        color: color,
        child: Text(number.toStringAsFixed(1)),
      );

  final Widget child;
  final Color? color;

  static double get preferredHeight => 24;

  @override
  Widget build(BuildContext context) => Container(
        height: preferredHeight,
        decoration: BoxDecoration(
          color: color ?? Colors.blue,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.visible,
          child: child,
        ),
      );
}
