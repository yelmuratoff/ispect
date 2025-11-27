import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectShareAllLogsBottomSheet extends StatefulWidget {
  const ISpectShareAllLogsBottomSheet({
    required this.controller,
    super.key,
  });

  final ISpectViewController controller;

  @override
  State<ISpectShareAllLogsBottomSheet> createState() =>
      _ISpectShareAllLogsBottomSheetState();

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

class _ISpectShareAllLogsBottomSheetState
    extends State<ISpectShareAllLogsBottomSheet> {
  @override
  Widget build(BuildContext context) => context.screenSizeMaybeWhen(
        phone: () => DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => _Body(
            controller: widget.controller,
          ),
        ),
        orElse: () {
          final iSpect = ISpect.read(context);
          final backgroundColor = iSpect.theme.background?.resolve(context);

          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            backgroundColor: backgroundColor,
            content: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.2,
              width: 500,
              child: _Body(
                controller: widget.controller,
              ),
            ),
          );
        },
      );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
  });

  final ISpectViewController controller;

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final backgroundColor = iSpect.theme.background?.resolve(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(
          Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _InfoDescription(
            controller: controller,
          ),
        ),
      ),
    );
  }
}

class _InfoDescription extends StatelessWidget {
  const _InfoDescription({
    required this.controller,
  });

  final ISpectViewController controller;

  @override
  Widget build(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;
    if (shareCallback == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ISpectBottomSheetHeader(title: context.ispectL10n.share),
        const Gap(16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  controller.shareLogsAsFile(ISpect.logger.history);
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.share_rounded,
                    ),
                    const Gap(8),
                    Flexible(
                      child: Text(
                        '${context.ispectL10n.shareLogsFile} (JSON)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  controller.shareLogsAsFile(
                    ISpect.logger.history,
                    fileType: 'txt',
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.share_rounded,
                    ),
                    const Gap(8),
                    Flexible(
                      child: Text(
                        '${context.ispectL10n.shareLogsFile} (txt)',
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
