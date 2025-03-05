import 'package:flutter/material.dart';

class JsonViewTheme {
  final TextStyle keyStyle;
  final TextStyle valueStyle;
  final TextStyle stringStyle;
  final TextStyle numberStyle;
  final TextStyle booleanStyle;
  final TextStyle nullStyle;
  final Color expandIconColor;
  final Color backgroundColor;
  final EdgeInsets nodePadding;

  const JsonViewTheme({
    this.keyStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.blue,
    ),
    this.valueStyle = const TextStyle(
      color: Colors.black87,
    ),
    this.stringStyle = const TextStyle(
      color: Colors.green,
    ),
    this.numberStyle = const TextStyle(
      color: Colors.purple,
    ),
    this.booleanStyle = const TextStyle(
      color: Colors.orange,
    ),
    this.nullStyle = const TextStyle(
      color: Colors.grey,
    ),
    this.expandIconColor = Colors.blue,
    this.backgroundColor = Colors.white,
    this.nodePadding = const EdgeInsets.symmetric(vertical: 2.0),
  });

  JsonViewTheme copyWith({
    TextStyle? keyStyle,
    TextStyle? valueStyle,
    TextStyle? stringStyle,
    TextStyle? numberStyle,
    TextStyle? booleanStyle,
    TextStyle? nullStyle,
    Color? expandIconColor,
    Color? backgroundColor,
    EdgeInsets? nodePadding,
  }) {
    return JsonViewTheme(
      keyStyle: keyStyle ?? this.keyStyle,
      valueStyle: valueStyle ?? this.valueStyle,
      stringStyle: stringStyle ?? this.stringStyle,
      numberStyle: numberStyle ?? this.numberStyle,
      booleanStyle: booleanStyle ?? this.booleanStyle,
      nullStyle: nullStyle ?? this.nullStyle,
      expandIconColor: expandIconColor ?? this.expandIconColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      nodePadding: nodePadding ?? this.nodePadding,
    );
  }
} 