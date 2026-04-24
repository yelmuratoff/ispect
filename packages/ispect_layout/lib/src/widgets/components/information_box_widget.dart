import 'package:flutter/material.dart';
import 'package:ispect_layout/src/number_format.dart';

class InformationBoxWidget extends StatelessWidget {
  const InformationBoxWidget({
    super.key,
    required this.child,
    this.color,
  });

  factory InformationBoxWidget.size({
    Key? key,
    required Size size,
    int decimalPlaces = 1,
    Color? color,
  }) {
    return InformationBoxWidget(
      key: key,
      color: color,
      child: Text(formatInspectorSize(size, decimalPlaces: decimalPlaces)),
    );
  }

  factory InformationBoxWidget.number({
    Key? key,
    required double number,
    int decimalPlaces = 1,
    Color? color,
  }) {
    return InformationBoxWidget(
      key: key,
      color: color,
      child: Text(
        formatInspectorDouble(number, decimalPlaces: decimalPlaces),
      ),
    );
  }

  final Widget child;
  final Color? color;

  static double get preferredHeight => 24.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredHeight,
      decoration: BoxDecoration(
        color: color ?? Colors.blue,
        borderRadius: BorderRadius.circular(4.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 14.0,
          color: Colors.white,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
        child: child,
      ),
    );
  }
}
