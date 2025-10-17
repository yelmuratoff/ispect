import 'package:flutter/material.dart';

class ExternalFileErrorWidget extends StatelessWidget {
  const ExternalFileErrorWidget({
    super.key,
    required this.fileName,
    required this.error,
  });

  final String fileName;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Path Detected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text('File: $fileName'),
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Как читать файлы в веб-браузере:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1. Откройте файл в текстовом редакторе',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
                Text(
                  '2. Скопируйте содержимое (Ctrl+A, Ctrl+C)',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
                Text(
                  '3. Нажмите кнопку "Load File" выше и вставьте содержимое',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Или перетащите файл прямо из редактора кода в эту область.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
