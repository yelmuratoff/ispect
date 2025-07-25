part of '../app_info_screen.dart';

/// A widget that displays a key-value pair with a dotted separator line
/// and styled chips for both key and value.
class KeyValueLine extends StatelessWidget {
  /// Creates a key-value line widget.
  const KeyValueLine({
    required this.k,
    required this.v,
    super.key,
  });

  /// The key text to display.
  final String k;

  /// The value text to display.
  final String v;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = adjustColor(
      color: theme.colorScheme.primary,
      value: 0.8,
      isDark: context.isDarkMode,
    );
    final chipDecoration = BoxDecoration(
      color: chipColor,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    );
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: getTextColorOnBackground(chipColor),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _DottedSeparator(color: chipColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Chip(text: k, style: style, decoration: chipDecoration),
              const Gap(32),
              Flexible(
                child: _TappableChip(
                  text: v,
                  style: style,
                  decoration: chipDecoration,
                  copyValue: '$k: $v',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.style,
    required this.decoration,
  });
  final String text;
  final TextStyle? style;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(text, style: style),
        ),
      );
}

class _TappableChip extends StatelessWidget {
  const _TappableChip({
    required this.text,
    required this.style,
    required this.decoration,
    required this.copyValue,
  });
  final String text;
  final TextStyle? style;
  final BoxDecoration decoration;
  final String copyValue;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        onTap: () => copyClipboard(context, value: copyValue),
        child: DecoratedBox(
          decoration: decoration,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              text,
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ),
      );
}

class _DottedSeparator extends StatelessWidget {
  const _DottedSeparator({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
        child: SizedBox(
          width: double.infinity,
          height: 2, // Increase height to accommodate larger dots
          child: CustomPaint(
            painter: _DotSeparatorPainter(
              dotSpacing: 6, // Increase spacing for better visual separation
              dotRadius: 0.8, // Slightly smaller radius for better fit
              color: color,
            ),
          ),
        ),
      );
}

/// A custom painter that draws evenly spaced dots in a horizontal line.
class _DotSeparatorPainter extends CustomPainter {
  /// Creates a dot separator painter.
  const _DotSeparatorPainter({
    required this.dotSpacing,
    required this.dotRadius,
    this.color,
  });

  /// The spacing between dots in logical pixels.
  final double dotSpacing;

  /// The radius of each dot in logical pixels.
  final double dotRadius;

  /// The color of the dots. If null, current theme's primary color will be used.
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? const Color(0xFF000000)
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final availableWidth =
        size.width - (2 * dotRadius); // Account for dot radius on both edges

    if (availableWidth <= 0) return; // Not enough space for even one dot

    // Calculate optimal number of dots that can fit with proper spacing
    final maxDotsWithSpacing = (availableWidth / dotSpacing).floor() + 1;

    if (maxDotsWithSpacing <= 1) {
      // Only one dot fits, center it
      canvas.drawCircle(Offset(size.width / 2, centerY), dotRadius, paint);
      return;
    }

    // Distribute dots evenly across available width
    final actualSpacing = availableWidth / (maxDotsWithSpacing - 1);
    final startX = dotRadius; // Start from radius to prevent left clipping

    for (var i = 0; i < maxDotsWithSpacing; i++) {
      final x = startX + (i * actualSpacing);
      canvas.drawCircle(Offset(x, centerY), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotSeparatorPainter oldDelegate) =>
      dotSpacing != oldDelegate.dotSpacing ||
      dotRadius != oldDelegate.dotRadius ||
      color != oldDelegate.color;
}
