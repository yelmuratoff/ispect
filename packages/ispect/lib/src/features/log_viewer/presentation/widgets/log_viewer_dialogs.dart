import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_alert_dialog.dart';
import 'package:ispect/src/common/widgets/ispect_input.dart';

/// Choice for how to load log content.
enum LogSourceChoice { external, paste }

/// Dialog to choose between loading log content from a file or pasting it.
class LogSourceDialog extends StatelessWidget {
  const LogSourceDialog({super.key});

  @override
  Widget build(BuildContext context) => ISpectAlertDialog(
        title: Text(context.ispectL10n.loadFileContent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.file_open),
              title: Text(context.ispectL10n.loadFileContent),
              subtitle: Text(context.ispectL10n.selectTxtOrJsonFromDevice),
              onTap: () => Navigator.of(context).pop(LogSourceChoice.external),
            ),
            const Gap(16),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: Text(context.ispectL10n.pasteContent),
              subtitle: Text(context.ispectL10n.pasteTxtOrJsonHere),
              onTap: () => Navigator.of(context).pop(LogSourceChoice.paste),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.ispectL10n.cancel),
          ),
        ],
      );
}

/// Dialog widget for pasting file content.
class PasteContentDialog extends StatefulWidget {
  const PasteContentDialog({
    required this.onContentProcessed,
    super.key,
  });

  final Future<void> Function(String content) onContentProcessed;

  @override
  State<PasteContentDialog> createState() => _PasteContentDialogState();
}

class _PasteContentDialogState extends State<PasteContentDialog> {
  final _controller = TextEditingController();
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    // ignore: cascade_invocations
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasContent = _controller.text.trim().isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() => _hasContent = hasContent);
    }
  }

  @override
  Widget build(BuildContext context) => ISpectAlertDialog(
        title: Text(context.ispectL10n.pasteContent),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.8,
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.ispectL10n.pasteYourFileContentBelow),
              const Gap(8),
              Expanded(
                child: ISpectTextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  hintText:
                      context.ispectL10n.pasteYourTxtOrJsonFileContentHere,
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.ispectL10n.cancel),
          ),
          ElevatedButton(
            onPressed: _hasContent
                ? () async {
                    Navigator.of(context).pop();
                    await widget.onContentProcessed(_controller.text);
                  }
                : null,
            child: Text(context.ispectL10n.process),
          ),
        ],
      );
}
