import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_helpers.dart';

class MethodBadge extends StatelessWidget {
  const MethodBadge({required this.method, required this.color, super.key});

  final String method;

  /// Fallback color for unknown methods (e.g. the `HTTP` placeholder).
  final Color color;

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        JsonColors.methodColorFor(method, Theme.of(context).brightness) ??
            color;
    return DecoratedBox(
      decoration: ISpectSquircle.decoration(
        color: badgeColor.withValues(alpha: 0.12),
        radius: ISpectConstants.smallBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          method,
          style: TextStyle(
            color: badgeColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: ISpectSquircle.decoration(
          color: color.withValues(alpha: 0.12),
          radius: ISpectConstants.mediumBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
}

class DesktopStatusBadge extends StatelessWidget {
  const DesktopStatusBadge({required this.statusCode, super.key});

  final int statusCode;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = JsonColors.statusCodeColors(statusCode);
    return Semantics(
      container: true,
      label: 'HTTP status $statusCode',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ISpectSquircle.decoration(
          color: bgColor.withValues(alpha: 0.12),
          radius: ISpectConstants.smallBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
}

class DurationBadge extends StatelessWidget {
  const DurationBadge({required this.duration, super.key});

  final Duration duration;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: ISpectSquircle.decoration(
          color: context.appTheme.textColor.withValues(alpha: 0.06),
          radius: ISpectConstants.smallBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            formatTransactionDuration(duration),
            style: TextStyle(
              color: context.appTheme.textColor.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
}

class PendingBadge extends StatelessWidget {
  const PendingBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: ISpectSquircle.decoration(
          color: JsonColors.statusWarning.withValues(alpha: 0.12),
          radius: ISpectConstants.smallBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            label,
            style: const TextStyle(
              color: JsonColors.statusWarningDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}

class DetailChip extends StatelessWidget {
  const DetailChip({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon = Icons.open_in_new_rounded,
    this.iconOnly = false,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final IconData icon;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: iconOnly
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!iconOnly) ...[
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(4),
          ],
          Icon(
            icon,
            size: iconOnly ? 14 : 12,
            color: color.withValues(alpha: 0.85),
          ),
        ],
      ),
    );

    final chip = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: DecoratedBox(
        decoration: ISpectSquircle.decoration(
          color: color.withValues(alpha: 0.08),
          radius: ISpectConstants.mediumBorderRadius,
        ),
        child: iconOnly
            ? content
            : SizedBox(
                height: ISpectConstants.actionControlHeight,
                child: content,
              ),
      ),
    );

    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: iconOnly
            ? Tooltip(message: label, child: chip)
            // Pad the touch target up to the minimum on the labeled mobile
            // chip while keeping the chip itself compact.
            : ConstrainedBox(
                constraints:
                    const BoxConstraints(minHeight: kMinInteractiveDimension),
                child: Center(widthFactor: 1, child: chip),
              ),
      ),
    );
  }
}

class SmallActionIcon extends StatelessWidget {
  const SmallActionIcon({
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
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: tooltip ?? '',
        onTap: onPressed,
        child: Tooltip(
          message: tooltip ?? '',
          child: InkWell(
            excludeFromSemantics: true,
            customBorder: ISpectSquircle.border(
              radius: ISpectConstants.smallBorderRadius,
            ),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                icon,
                size: 15,
                color: color.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
}
