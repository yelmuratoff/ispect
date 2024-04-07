import 'package:flutter/material.dart';

final class ISpectToaster {
  static Future<void> showErrorToast(
    BuildContext context, {
    required String title,
    String? message,
  }) =>
      _showToast(
        context,
        title: title,
        message: message,
        color: Colors.red,
      );

  static Future<void> showInfoToast(
    BuildContext context, {
    required String title,
    String? message,
  }) =>
      _showToast(
        context,
        title: title,
        message: message,
        color: const Color.fromARGB(255, 49, 49, 49),
      );

  static Future<void> showSuccessToast(
    BuildContext context, {
    required String title,
    String? message,
  }) =>
      _showToast(
        context,
        title: title,
        message: message,
        color: Colors.green,
      );

  static Future<void> _showToast(
    BuildContext context, {
    required String title,
    String? message,
    required Color color,
  }) async =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: color,
          elevation: 0,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (message != null)
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
}
