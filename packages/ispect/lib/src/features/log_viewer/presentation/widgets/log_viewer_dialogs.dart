import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_alert_dialog.dart';
import 'package:ispect/src/common/widgets/ispect_input.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/action_tile.dart';

/// Choice for how to load log content.
enum LogSourceChoice { external, paste }

const _dialogTitlePadding = EdgeInsets.fromLTRB(20, 20, 20, 8);
const _dialogContentPadding = EdgeInsets.fromLTRB(20, 0, 20, 8);
const _dialogActionsPadding = EdgeInsets.fromLTRB(20, 8, 20, 16);

/// Dialog to choose between loading log content from a file or pasting it.
class LogSourceDialog extends StatelessWidget {
  const LogSourceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    return ISpectAlertDialog(
      titlePadding: _dialogTitlePadding,
      contentPadding: _dialogContentPadding,
      actionsPadding: _dialogActionsPadding,
      title: ISpectDialogHeader(
        title: l10n.importLogs,
        subtitle: l10n.chooseHowToLoadYourFile,
        icon: Icons.file_open_outlined,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActionRow(
            icon: Icons.upload_file_outlined,
            title: l10n.loadFileContent,
            description: l10n.selectTxtOrJsonFromDevice,
            onTap: () => Navigator.of(context).pop(LogSourceChoice.external),
          ),
          const Gap(8),
          ActionRow(
            icon: Icons.content_paste_rounded,
            title: l10n.pasteContent,
            description: l10n.pasteTxtOrJsonHere,
            onTap: () => Navigator.of(context).pop(LogSourceChoice.paste),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

/// Dialog widget for pasting file content.
class PasteContentDialog extends StatefulWidget {
  const PasteContentDialog({required this.onContentProcessed, super.key});

  final Future<void> Function(String content) onContentProcessed;

  @override
  State<PasteContentDialog> createState() => _PasteContentDialogState();
}

class _PasteContentDialogState extends State<PasteContentDialog> {
  final _controller = TextEditingController();
  bool _showEmptyError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    if (_showEmptyError) setState(() => _showEmptyError = false);
  }

  Future<void> _submit() async {
    final content = _controller.text;
    if (content.trim().isEmpty) {
      setState(() => _showEmptyError = true);
      return;
    }
    Navigator.of(context).pop();
    await widget.onContentProcessed(content);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    final screen = MediaQuery.sizeOf(context);
    return ISpectAlertDialog(
      titlePadding: _dialogTitlePadding,
      contentPadding: _dialogContentPadding,
      actionsPadding: _dialogActionsPadding,
      title: ISpectDialogHeader(
        title: l10n.pasteContent,
        subtitle: l10n.pasteTxtOrJsonHere,
        icon: Icons.content_paste_rounded,
      ),
      content: SizedBox(
        width: (screen.width * 0.8).clamp(0, ISpectConstants.wideModalMaxWidth),
        height: screen.height * 0.5,
        child: ISpectTextField(
          controller: _controller,
          autofocus: true,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          hintText: l10n.pasteYourTxtOrJsonFileContentHere,
          errorText: _showEmptyError ? l10n.contentEmptyError : null,
          onChanged: _onChanged,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.process)),
      ],
    );
  }
}
