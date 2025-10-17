import 'package:flutter/material.dart';

class PasteDialog extends StatefulWidget {
  const PasteDialog({super.key, required this.onProcess});

  final void Function(String content, String format) onProcess;

  @override
  State<PasteDialog> createState() => PasteDialogState();
}

class PasteDialogState extends State<PasteDialog> {
  final TextEditingController _controller = TextEditingController();
  String _selectedFormat = 'auto';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paste File Content'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Format: '),
                DropdownButton<String>(
                  value: _selectedFormat,
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Auto-detect')),
                    DropdownMenuItem(value: 'json', child: Text('JSON')),
                    DropdownMenuItem(value: 'text', child: Text('Plain Text')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Paste your file content below:'),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste your .txt or .json file content here...',
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop();
              widget.onProcess(_controller.text, _selectedFormat);
            }
          },
          child: const Text('Process'),
        ),
      ],
    );
  }
}
