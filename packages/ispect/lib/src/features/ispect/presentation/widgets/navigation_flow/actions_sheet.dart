import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/observers/route_extension.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectNavigationFlowActionsSheet extends StatelessWidget {
  const ISpectNavigationFlowActionsSheet({
    required this.log,
    required this.transition,
    required this.items,
    super.key,
  });

  final RouteLog? log;
  final RouteTransition? transition;
  final List<RouteTransition> items;

  Future<void> show(BuildContext context) async => context.screenSizeMaybeWhen(
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

  @override
  Widget build(BuildContext context) => context.screenSizeMaybeWhen(
        phone: () => DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => _ActionsSheetContent(
            log: log,
            transition: transition,
            items: items,
          ),
        ),
        orElse: () => AlertDialog(
          contentPadding: EdgeInsets.zero,
          backgroundColor: context.ispectTheme.scaffoldBackgroundColor,
          content: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.2,
            width: 500,
            child: _ActionsSheetContent(
              log: log,
              transition: transition,
              items: items,
            ),
          ),
        ),
      );
}

class _ActionsSheetContent extends StatelessWidget {
  const _ActionsSheetContent({
    required this.log,
    required this.transition,
    required this.items,
  });

  final RouteLog? log;
  final RouteTransition? transition;
  final List<RouteTransition> items;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ISpectBottomSheetHeader(title: context.ispectL10n.share),
              const Gap(16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (context.iSpect.options.onShare != null)
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          final String text;
                          if (transition == null) {
                            text = items.transitionsText();
                          } else {
                            text = items.transitionsToId(
                              transition!.id,
                              isTruncated: false,
                            );
                          }
                          LogsFileFactory.downloadFile(
                            text,
                            fileName: 'ispect_navigation_flow',
                            onShare: context.iSpect.options.onShare,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.share_rounded),
                            const Gap(8),
                            Flexible(
                              child: Text(context.ispectL10n.shareLogFull),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final String text;
                        if (transition == null) {
                          text = items.transitionsText();
                        } else {
                          text = items.transitionsToId(transition!.id);
                        }
                        copyClipboard(
                          context,
                          value: text,
                          showValue: false,
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded),
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
          ),
        ),
      ),
    );
  }
}
