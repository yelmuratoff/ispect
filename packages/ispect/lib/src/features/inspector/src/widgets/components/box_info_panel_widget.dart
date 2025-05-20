import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';

import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';
import 'package:ispect/src/features/inspector/src/widgets/inspector/box_info.dart';

class BoxInfoPanelWidget extends StatelessWidget {
  const BoxInfoPanelWidget({
    required this.boxInfo,
    required this.targetColor,
    required this.containerColor,
    required this.onVisibilityChanged,
    super.key,
    this.isVisible = true,
  });

  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;
  final BoxInfo boxInfo;
  final Color targetColor;
  final Color containerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iSpect = ISpect.read(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    describeIdentity(boxInfo.targetRenderBox),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: .1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    copyClipboard(
                      context,
                      value: boxInfo.targetRenderBox.toStringDeep(),
                      showValue: false,
                    );
                  },
                  child: Center(
                    child: Text(
                      context.ispectL10n.copy,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 12,
            ),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (boxInfo.containerRect != null) ...[
                _MainRow(boxInfo: boxInfo),
              ],
              if (boxInfo.targetRenderBox is RenderParagraph) ...[
                Divider(
                  height: 16,
                  color:
                      iSpect.theme.dividerColor(context) ?? theme.dividerColor,
                ),
                _RenderParagraphInfo(boxInfo: boxInfo),
              ],
              if (boxInfo.targetRenderBox is RenderDecoratedBox) ...[
                Divider(
                  height: 16,
                  color:
                      iSpect.theme.dividerColor(context) ?? theme.dividerColor,
                ),
                _RenderDecoratedBoxInfo(boxInfo: boxInfo),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.child,
    required this.subtitle,
    this.iconColor,
    this.backgroundColor,
  });
  final IconData icon;
  final Widget child;
  final String subtitle;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child0 = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            const SizedBox(height: 0),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ],
    );

    if (backgroundColor != null) {
      child0 = Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: child0,
      );
    }

    return child0;
  }
}

class _MainRow extends StatelessWidget {
  const _MainRow({
    required this.boxInfo,
  });
  final BoxInfo boxInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _InfoRow(
          icon: Icons.format_shapes,
          subtitle: 'size',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(
            '${boxInfo.targetRect.width} × ${boxInfo.targetRect.height}',
          ),
        ),
        _InfoRow(
          icon: Icons.straighten,
          subtitle: 'padding (LTRB)',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(boxInfo.describePadding()),
        ),
      ],
    );
  }
}

class _RenderDecoratedBoxInfo extends StatelessWidget {
  const _RenderDecoratedBoxInfo({required this.boxInfo});
  final BoxInfo boxInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final decoration = boxInfo.decoration;
    if (decoration == null) return const SizedBox.shrink();

    if (decoration is BoxDecoration) {
      final border = boxInfo.getDecoratedBoxBorder();
      final borderRadius = boxInfo.getDecoratedBoxBorderRadius();
      final shape = boxInfo.getDecoratedBoxShape();
      final color = boxInfo.getDecoratedBoxColor();
      final boxShadow = boxInfo.getDecoratedBoxShadow();
      final gradient = boxInfo.getDecoratedBoxGradient();
      final blendMode = boxInfo.getDecoratedBoxBackgroundBlendMode();
      final image = boxInfo.getDecoratedBoxImage();

      return Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          if (borderRadius != null)
            _InfoRow(
              icon: Icons.rounded_corner,
              subtitle: 'border radius',
              backgroundColor: theme.chipTheme.backgroundColor,
              child: Text(borderRadius.toString()),
            ),
          if (shape != null)
            _InfoRow(
              icon: Icons.circle_outlined,
              subtitle: 'shape',
              backgroundColor: theme.chipTheme.backgroundColor,
              child: Text(shape.toString()),
            ),
          if (color != null)
            _InfoRow(
              icon: Icons.palette,
              subtitle: 'color',
              backgroundColor: theme.chipTheme.backgroundColor,
              iconColor: color,
              child: Text(
                '#${colorToHexString(color, withAlpha: true)}',
                style: TextStyle(color: color),
              ),
            ),
          if (border != null)
            _InfoRow(
              icon: Icons.border_all,
              subtitle: 'border',
              backgroundColor: theme.chipTheme.backgroundColor,
              child: Text(border.toString()),
            ),
          if (boxShadow != null && boxShadow.isNotEmpty)
            _InfoRow(
              icon: Icons.blur_on,
              subtitle: 'boxShadow',
              backgroundColor: theme.chipTheme.backgroundColor,
              child: Text(boxShadow.map((e) => e.toString()).join(',\n')),
            ),
          if (gradient != null)
            _InfoRow(
              icon: Icons.gradient,
              subtitle: 'gradient',
              backgroundColor: theme.chipTheme.backgroundColor,
              child: Text(gradient.toString()),
            ),
          if (blendMode != null)
            _InfoRow(
              icon: Icons.layers,
              subtitle: 'backgroundBlendMode',
              backgroundColor: theme.chipTheme.backgroundColor,
              child: Text(blendMode.toString()),
            ),
          if (image != null)
            _InfoRow(
              icon: Icons.image,
              subtitle: 'image',
              backgroundColor: theme.chipTheme.backgroundColor,
              child: Text(image.toString()),
            ),
        ],
      );
    }

    return _InfoRow(
      icon: Icons.info_outline,
      subtitle: 'decoration',
      backgroundColor: theme.chipTheme.backgroundColor,
      child: Text(decoration.toString()),
    );
  }
}

class _RenderParagraphInfo extends StatelessWidget {
  const _RenderParagraphInfo({required this.boxInfo});
  final BoxInfo boxInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final renderParagraph = boxInfo.targetRenderBox as RenderParagraph;

    final style = renderParagraph.text.style;

    if (style == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _InfoRow(
          icon: Icons.font_download,
          subtitle: 'font family',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.fontFamily ?? 'n/a'),
        ),
        _InfoRow(
          icon: Icons.format_size,
          subtitle: 'font size',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.fontSize?.toStringAsFixed(1) ?? 'n/a'),
        ),
        _InfoRow(
          icon: Icons.text_format,
          subtitle: 'decoration',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.decoration?.toString() ?? 'n/a'),
        ),
        _InfoRow(
          icon: Icons.color_lens,
          subtitle: 'color',
          iconColor: style.color,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(
            renderParagraph.text.style?.color != null
                ? '#${colorToHexString(style.color!, withAlpha: true)}'
                : 'n/a',
            style: TextStyle(
              color: style.color,
            ),
          ),
        ),
        _InfoRow(
          icon: Icons.height,
          subtitle: 'height',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.height?.toStringAsFixed(1) ?? 'n/a'),
        ),
        _InfoRow(
          icon: Icons.line_weight,
          subtitle: 'weight',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.fontWeight?.toString() ?? 'n/a'),
        ),
      ],
    );
  }
}
