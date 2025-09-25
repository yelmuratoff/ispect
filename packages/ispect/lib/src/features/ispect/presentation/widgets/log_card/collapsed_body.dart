part of 'log_card.dart';

class CollapsedBody extends StatelessWidget {
  const CollapsedBody({
    required this.icon,
    required this.color,
    required this.title,
    required this.dateTime,
    required this.onCopyTap,
    required this.onCopyCurlTap,
    required this.onExpandTap,
    required this.onRouteTap,
    required this.message,
    required this.errorMessage,
    required this.expanded,
    required this.isHTTP,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String? title;
  final String dateTime;
  final VoidCallback? onCopyTap;
  final VoidCallback? onCopyCurlTap;
  final VoidCallback? onExpandTap;
  final VoidCallback? onRouteTap;

  final String? message;
  final String? errorMessage;
  final bool expanded;
  final bool isHTTP;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedLeadingIcon(icon: icon, color: color),
                    const Gap(6),
                    Flexible(
                      child: Text(
                        '$title | $dateTime',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!expanded)
                  _CollapsedMessage(
                    color: color,
                    message: message,
                    errorMessage: errorMessage,
                  ),
              ],
            ),
          ),
          if (onRouteTap != null) ...[
            SquareIconButton(
              icon: Icons.compare_arrows_rounded,
              color: color,
              onPressed: onRouteTap,
            ),
            const Gap(4),
          ],
          SquareIconButton(
            icon: Icons.copy_rounded,
            color: color,
            onPressed: onCopyTap,
          ),
          const Gap(4),
          if (isHTTP) ...[
            SquareIconButton(
              icon: Icons.terminal_rounded,
              color: color,
              onPressed: onCopyCurlTap,
            ),
            const Gap(4),
          ],
          SquareIconButton(
            icon: Icons.zoom_out_map_rounded,
            color: color,
            onPressed: onExpandTap,
          ),
        ],
      );
}

class _CollapsedMessage extends StatelessWidget {
  const _CollapsedMessage({
    required this.color,
    required this.message,
    required this.errorMessage,
  });

  final Color color;
  final String? message;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final displayMessage =
        (message == 'FlutterErrorDetails') ? errorMessage : message;

    if (displayMessage == null || displayMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        displayMessage,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 24,
        child: IconButton(
          iconSize: 16,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            backgroundColor: color.withValues(alpha: 0.1),
          ),
          icon: Icon(
            icon,
            color: context.ispectTheme.colorScheme.onSurface
                .withValues(alpha: 0.5),
          ),
          onPressed: onPressed,
        ),
      );
}

class DecoratedLeadingIcon extends StatelessWidget {
  const DecoratedLeadingIcon({
    required this.icon,
    required this.color,
    super.key,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
      );
}
