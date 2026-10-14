import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

import '../../../../core/utils/utils.dart';

class FileContentWidget extends StatelessWidget {
  FileContentWidget({
    super.key,
    required this.content,
    required this.file,
    required this.inspection,
  }) : contentSizeInBytes = utf8.encode(content).length;

  final String content;
  final dynamic file;
  final FileInspection inspection;
  final int contentSizeInBytes;

  String get displayName => inspection.type.displayName;
  String get mimeType => inspection.type.mimeType;

  @override
  Widget build(BuildContext context) {
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
          Text('File Size: ${formatFileSize(contentSizeInBytes)}'),
          const SizedBox(height: 8),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () async {
              final jsonError = inspection.jsonError;
              if (jsonError != null) {
                ISpectToaster.showErrorToast(
                  context,
                  title: 'Invalid JSON',
                  message: jsonError.message,
                );
                return;
              }
              final data = await viewerContent(content, inspection);
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => JsonScreen(
                    data: {
                      'display_name': displayName,
                      'mime_type': mimeType,
                      'file_name': file.fileName,
                      'size': formatFileSize(contentSizeInBytes),
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
}
