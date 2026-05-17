part of 'log_card.dart';

class CollapsedBody extends StatelessWidget {
  const CollapsedBody({
    required this.icon,
    required this.color,
    required this.title,
    required this.dateTime,
    required this.onExpandTap,
    required this.onMenuTap,
    required this.message,
    required this.errorMessage,
    required this.expanded,
    this.subtitle,
    this.statusCode,
    this.slowDurationMs,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String? title;
  final String dateTime;
  final VoidCallback? onExpandTap;
  final VoidCallback? onMenuTap;

  final String? message;
  final String? errorMessage;
  final bool expanded;

  /// Subtitle shown below the title row when [expanded] is `true`.
  /// Use it to surface stable context (log id, level, source) that is not
  /// duplicated by the message body shown beneath the divider.
  final String? subtitle;

  final int? statusCode;
  final int? slowDurationMs;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: DecoratedLeadingIcon(icon: icon, color: color),
          ),
          const Gap(ISpectConstants.standardGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.1,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const Gap(6),
                    Text(
                      dateTime,
                      maxLines: 1,
                      style: TextStyle(
                        color:
                            context.appTheme.textColor.withValues(alpha: 0.45),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                if (expanded) ...[
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              context.appTheme.textColor.withValues(alpha: 0.5),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                          letterSpacing: 0.1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ] else
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
          SquareIconButton(
            icon: Icons.open_in_full_rounded,
            color: color,
            tooltip: context.ispectL10n.expandLogs,
            onPressed: onExpandTap,
          ),
          SquareIconButton(
            icon: Icons.more_vert_rounded,
            color: color,
            tooltip: context.ispectL10n.actions,
            onPressed: onMenuTap,
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
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        displayMessage,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.appTheme.textColor.withValues(alpha: 0.7),
          fontSize: 11,
          height: 1.25,
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
    Widget button = Semantics(
      button: true,
      label: tooltip ?? '',
      onTap: onPressed,
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.all(Radius.circular(7)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  icon,
                  size: 13,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
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
          color: color.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.all(Radius.circular(7)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            icon,
            color: color,
            size: 14,
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
    return Semantics(
      container: true,
      label: 'HTTP status $statusCode',
      excludeSemantics: true,
      child: DecoratedBox(
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
      ),
    );
  }

  static (Color, Color) _colorsForStatus(int code) => switch (code) {
        < 300 => (const Color(0xFF4CAF50), const Color(0xFF2E7D32)),
        < 400 => (const Color(0xFFFF9800), const Color(0xFFE65100)),
        _ => (const Color(0xFFF44336), const Color(0xFFC62828)),
      };
}
