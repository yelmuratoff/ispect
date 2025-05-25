import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/download_logs/download_logs.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectShareLogBottomSheet extends StatefulWidget {
  const ISpectShareLogBottomSheet({
    required this.value,
    super.key,
  });

  @override
  State<ISpectShareLogBottomSheet> createState() =>
      _ISpectShareLogBottomSheetState();

  final ISpectifyData value;
}

class _ISpectShareLogBottomSheetState extends State<ISpectShareLogBottomSheet> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => context.screenSizeMaybeWhen(
        phone: () => DraggableScrollableSheet(
          initialChildSize: 0.2,
          minChildSize: 0.2,
          maxChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) => _Body(
            value: widget.value,
          ),
        ),
        orElse: () => AlertDialog(
          contentPadding: EdgeInsets.zero,
          backgroundColor: context.ispectTheme.scaffoldBackgroundColor,
          content: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.2,
            width: 500,
            child: _Body(
              value: widget.value,
            ),
          ),
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.value,
  });

  final ISpectifyData value;

  @override
  Widget build(BuildContext context) {
    final theme = context.ispectTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.all(
          Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _InfoDescription(
            value: value,
          ),
        ),
      ),
    );
  }
}

class _InfoDescription extends StatelessWidget {
  const _InfoDescription({
    required this.value,
  });

  final ISpectifyData value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _Header(title: context.ispectL10n.share),
          const Gap(16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final text = value.toJson();
                    final valueToShare = JsonTruncatorService.pretty(
                      text,
                      maxDepth: 500,
                    );

                    Navigator.of(context).pop();

                    downloadFile(
                      valueToShare,
                      fileName: 'ispect_log',
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.share_rounded,
                      ),
                      const Gap(8),
                      Text(context.ispectL10n.shareLogFull),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final text = value.toJson(truncated: true);
                    final valueToShare = JsonTruncatorService.pretty(
                      text,
                    );

                    Navigator.of(context).pop();

                    copyClipboard(
                      context,
                      value: valueToShare,
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                      ),
                      const Gap(8),
                      Text(context.ispectL10n.copyToClipboardTruncated),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = context.ispectTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:
              theme.textTheme.headlineSmall?.copyWith(color: theme.textColor),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, color: theme.textColor),
        ),
      ],
    );
  }
}
