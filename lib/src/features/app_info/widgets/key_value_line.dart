part of '../app.dart';

class KeyValueLine extends StatelessWidget {
  const KeyValueLine({
    required this.k,
    required this.v,
    super.key,
  });

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.ispectTheme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    k,
                    style: context.ispectTheme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 5,
              child: Divider(
                color: context.ispectTheme.dividerColor,
              ),
            ),
            Flexible(
              flex: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: "$k $v"));
                  ISpectToaster.showInfoToast(
                    context,
                    title: context.ispectL10n.copied_to_clipboard,
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.ispectTheme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      v,
                      textAlign: TextAlign.end,
                      style: context.ispectTheme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
