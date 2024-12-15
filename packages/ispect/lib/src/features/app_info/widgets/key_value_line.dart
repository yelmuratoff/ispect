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
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.ispectTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
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
              color: iSpect.theme.dividerColor(context) ??
                  context.ispectTheme.dividerColor,
            ),
          ),
          Flexible(
            flex: 2,
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              onTap: () {
                copyClipboard(context, value: '$k $v');
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.ispectTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
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
}
