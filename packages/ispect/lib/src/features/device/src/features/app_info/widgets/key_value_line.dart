part of '../app_info_screen.dart';

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
    final theme = Theme.of(context);
    final chipDecoration = BoxDecoration(
      color: adjustColor(
        color: theme.colorScheme.primary,
        value: 0.8,
        isDark: theme.colorScheme.brightness == Brightness.dark,
      ),
      borderRadius: const BorderRadius.all(
        Radius.circular(8),
      ),
    );
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: getTextColorOnBackground(chipDecoration.color!),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            child: SizedBox(
              width: double.infinity,
              height: 1,
              child: CustomPaint(
                painter: DotSeparatorPainter(
                  color: chipDecoration.color!,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DecoratedBox(
                decoration: chipDecoration,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    k,
                    style: style,
                  ),
                ),
              ),
              const Gap(32),
              Flexible(
                child: InkWell(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(8),
                  ),
                  onTap: () => copyClipboard(context, value: '$k: $v'),
                  child: DecoratedBox(
                    decoration: chipDecoration,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        v,
                        textAlign: TextAlign.end,
                        style: style,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DotSeparatorPainter extends CustomPainter {
  const DotSeparatorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dotSpacing = 4.0;
    const dotRadius = 1.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += dotSpacing) {
      canvas.drawCircle(Offset(x, size.height / 2), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DotSeparatorPainter oldDelegate) =>
      oldDelegate.color != color;
}
