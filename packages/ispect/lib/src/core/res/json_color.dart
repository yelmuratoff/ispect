import 'package:flutter/material.dart';

class JsonColors {
  JsonColors._();

  static const nullColor = Colors.grey;
  static const boolColor = Colors.orange;

  static const jsonTreeColor = Color(0xFF2D45C3);
  static const objectColor = Color(0xFF9E9E9E);
  static const intColor = Color(0xFF199B4D);
  static const doubleColor = Color(0xFF199B4D);
  static const stringColor = Color(0xFFCD44D9);
  static const jsonBackgroundColor = Color(0xFFE8E8E8);
  static const jsonKeyColor = Color(0xFF2D45C3);
  static const hiddenContainerColor = Color(0xFFBB5BC3);

  static Color getStatusColor(int? statusCode) {
    if (statusCode == null) {
      return Colors.grey;
    } else if (statusCode >= 200 && statusCode < 300) {
      return Colors.green;
    } else if (statusCode >= 400 && statusCode < 500) {
      return Colors.orange;
    } else if (statusCode >= 500) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
