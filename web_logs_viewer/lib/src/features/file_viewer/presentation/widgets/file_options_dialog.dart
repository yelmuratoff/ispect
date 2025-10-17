import 'package:flutter/material.dart';

class FileOptionsDialog extends StatelessWidget {
  const FileOptionsDialog({
    super.key,
    required this.onPaste,
    required this.onPick,
  });

  final VoidCallback onPaste;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Load File Content'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose how to load your file:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.content_paste),
            title: const Text('Paste Content'),
            subtitle: const Text(
              'Copy .txt or .json file content and paste it here',
            ),
            onTap: () {
              Navigator.of(context).pop();
              onPaste();
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.content_paste),
            title: const Text('Pick Files'),
            subtitle: const Text('Select .txt or .json files from your device'),
            onTap: () {
              Navigator.of(context).pop();
              onPick();
            },
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            '💡 Tip: You can also drag and drop .txt or .json files directly to the drop zone above.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '⚠️ Only .txt and .json files are supported.',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
