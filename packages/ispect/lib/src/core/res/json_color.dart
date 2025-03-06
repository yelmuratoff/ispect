import 'package:flutter/material.dart';

class JsonColors {
  JsonColors._();

  static const nullColor = Colors.grey;
  static const boolColor = Colors.orange;

  static const jsonTreeColor = Color(0xFF2D45C3);
  static const objectColor = Colors.blue;
  static const arrayColor = Colors.blue;
  static const numColor = Colors.purpleAccent;
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
      return Colors.red;
    } else if (statusCode >= 500) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  static const methodColors = {
    'GET': Colors.green,
    'POST': Colors.blue,
    'PUT': Colors.orange,
    'DELETE': Colors.red,
    'PATCH': Colors.purple,
    'HEAD': Colors.pink,
    'OPTIONS': Colors.teal,
    'TRACE': Colors.grey,
    'CONNECT': Colors.brown,
  };
}
