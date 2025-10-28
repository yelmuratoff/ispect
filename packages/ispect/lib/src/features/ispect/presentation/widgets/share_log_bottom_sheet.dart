import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectShareLogBottomSheet extends StatefulWidget {
  const ISpectShareLogBottomSheet({
    required this.data,
    required this.truncatedData,
    super.key,
  });

  @override
  State<ISpectShareLogBottomSheet> createState() =>
      _ISpectShareLogBottomSheetState();

  final Map<String, dynamic> data;
  final Map<String, dynamic> truncatedData;

  Future<void> show(BuildContext context) async {
    await context.screenSizeMaybeWhen(
      phone: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => this,
      ),
      orElse: () => showDialog<void>(
        context: context,
        builder: (_) => this,
      ),
    );
  }
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
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => _Body(
            data: widget.data,
            truncatedData: widget.truncatedData,
          ),
        ),
        orElse: () => AlertDialog(
          contentPadding: EdgeInsets.zero,
          backgroundColor: context.ispectTheme.scaffoldBackgroundColor,
          content: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.2,
            width: 500,
            child: _Body(
              data: widget.data,
              truncatedData: widget.truncatedData,
            ),
          ),
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.data,
    required this.truncatedData,
  });

  final Map<String, dynamic> data;
  final Map<String, dynamic> truncatedData;

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
            data: data,
            truncatedData: truncatedData,
          ),
        ),
      ),
    );
  }
}

class _InfoDescription extends StatelessWidget {
  const _InfoDescription({
    required this.data,
    required this.truncatedData,
  });

  final Map<String, dynamic> data;
  final Map<String, dynamic> truncatedData;

  @override
  Widget build(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;

    return Column(
      children: [
        ISpectBottomSheetHeader(title: context.ispectL10n.share),
        const Gap(16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (shareCallback != null)
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final valueToShare = JsonTruncatorService.pretty(
                      data,
                      maxDepth: 500,
                      maxIterableSize: 10000,
                    );

                    Navigator.of(context).pop();

                    LogsFileFactory.downloadFile(
                      valueToShare,
                      fileName: 'ispect_log',
                      onShare: shareCallback,
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.share_rounded,
                      ),
                      const Gap(8),
                      Flexible(child: Text(context.ispectL10n.shareLogFull)),
                    ],
                  ),
                ),
              ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final valueToShare = JsonTruncatorService.pretty(
                    truncatedData,
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
                    Flexible(
                      child: Text(
                        context.ispectL10n.copyToClipboardTruncated,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
