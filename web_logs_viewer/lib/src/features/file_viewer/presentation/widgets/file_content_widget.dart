import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

import '../../../../core/utils/utils.dart';

class FileContentWidget extends StatelessWidget {
  const FileContentWidget({
    super.key,
    required this.content,
    required this.file,
    required this.displayName,
    required this.mimeType,
  });

  final String content;
  final dynamic file;
  final String displayName;
  final String mimeType;

  @override
  Widget build(BuildContext context) {
    final int? fileLength = _getFileLengthSafely(file);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$displayName File',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.cyan.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'MIME Type: $mimeType',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          if (file.fileName != null) ...[
            Text('File Name: ${file.fileName}'),
            const SizedBox(height: 4),
          ],
          if (fileLength != null) ...[
            Text('File Size: ${formatFileSize(fileLength)}'),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              dynamic data;
              if (mimeType == 'application/json') {
                data = jsonDecode(content);
              } else {
                data = content;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => JsonScreen(
                    data: {
                      'display_name': displayName,
                      'mime_type': mimeType,
                      'file_name': file.fileName,
                      if (fileLength != null)
                        'size': formatFileSize(fileLength),
                      'content': data,
                    },
                  ),
                ),
              );
            },
            child: const Text('View in JSON Viewer'),
          ),
        ],
      ),
    );
  }

  int? _getFileLengthSafely(dynamic file) {
    try {
      if (file.runtimeType.toString().contains('length')) {
        return file.length as int?;
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }
}
