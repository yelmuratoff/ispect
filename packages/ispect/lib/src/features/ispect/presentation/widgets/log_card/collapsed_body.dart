part of 'log_card.dart';

class CollapsedBody extends StatelessWidget {
  const CollapsedBody({
    required this.icon,
    required this.color,
    required this.title,
    required this.dateTime,
    required this.onShareTap,
    required this.onCopyCurlTap,
    required this.onExpandTap,
    required this.onRouteTap,
    required this.message,
    required this.errorMessage,
    required this.expanded,
    required this.isHTTP,
    this.statusCode,
    this.slowDurationMs,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String? title;
  final String dateTime;
  final VoidCallback? onShareTap;
  final VoidCallback? onCopyCurlTap;
  final VoidCallback? onExpandTap;
  final VoidCallback? onRouteTap;

  final String? message;
  final String? errorMessage;
  final bool expanded;
  final bool isHTTP;
  final int? statusCode;
  final int? slowDurationMs;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedLeadingIcon(icon: icon, color: color),
                    const Gap(ISpectConstants.standardGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            dateTime,
                            maxLines: 1,
                            style: TextStyle(
                              color: context.appTheme.textColor
                                  .withValues(alpha: 0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
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
          if (statusCode != null) ...[
            const Gap(4),
            _StatusCodeBadge(statusCode: statusCode!),
          ],
          if (slowDurationMs != null) ...[
            const Gap(4),
            SlowBadge(durationMs: slowDurationMs!),
          ],
          const Gap(4),
          _ActionButtons(
            color: color,
            onShareTap: onShareTap,
            onCopyCurlTap: onCopyCurlTap,
            onExpandTap: onExpandTap,
            onRouteTap: onRouteTap,
            isHTTP: isHTTP,
          ),
        ],
      );
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.color,
    required this.onShareTap,
    required this.onCopyCurlTap,
    required this.onExpandTap,
    required this.onRouteTap,
    required this.isHTTP,
  });

  final Color color;
  final VoidCallback? onShareTap;
  final VoidCallback? onCopyCurlTap;
  final VoidCallback? onExpandTap;
  final VoidCallback? onRouteTap;
  final bool isHTTP;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onRouteTap != null) ...[
            SquareIconButton(
              icon: Icons.compare_arrows_rounded,
              color: color,
              tooltip: context.ispectL10n.navigationFlow,
              onPressed: onRouteTap,
            ),
            const Gap(2),
          ],
          SquareIconButton(
            icon: Icons.share_rounded,
            color: color,
            tooltip: context.ispectL10n.share,
            onPressed: onShareTap,
          ),
          const Gap(3),
          if (isHTTP) ...[
            SquareIconButton(
              icon: Icons.terminal_rounded,
              color: color,
              tooltip: context.ispectL10n.copyAsCurl,
              onPressed: onCopyCurlTap,
            ),
            const Gap(2),
          ],
          SquareIconButton(
            icon: Icons.open_in_full_rounded,
            color: color,
            tooltip: context.ispectL10n.expandLogs,
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
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        displayMessage,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.appTheme.textColor.withValues(alpha: 0.6),
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
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 15,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );

    if (tooltip case final tooltip?) {
      button = Tooltip(message: tooltip, child: button);
    }

    return button;
  }
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
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
      );
}

class _StatusCodeBadge extends StatelessWidget {
  const _StatusCodeBadge({required this.statusCode});

  final int statusCode;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = _colorsForStatus(statusCode);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          '$statusCode',
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  static (Color, Color) _colorsForStatus(int code) => switch (code) {
        < 300 => (const Color(0xFF4CAF50), const Color(0xFF2E7D32)),
        < 400 => (const Color(0xFFFF9800), const Color(0xFFE65100)),
        _ => (const Color(0xFFF44336), const Color(0xFFC62828)),
      };
}
