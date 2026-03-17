import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/features/inspector/src/inspector/box_info.dart';
import 'package:ispect/src/features/inspector/src/utils.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';

class BoxInfoPanelWidget extends StatelessWidget {
  const BoxInfoPanelWidget({
    required this.boxInfo,
    required this.targetColor,
    required this.containerColor,
    required this.onVisibilityChanged,
    required this.onEnterCompareMode,
    required this.onExitCompareMode,
    super.key,
    this.comparedBoxInfo,
    this.isCompareMode = false,
    this.isVisible = true,
  });

  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;
  final BoxInfo boxInfo;
  final BoxInfo? comparedBoxInfo;
  final bool isCompareMode;
  final Color targetColor;
  final Color containerColor;
  final VoidCallback onEnterCompareMode;
  final VoidCallback onExitCompareMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iSpect = ISpect.read(context);
    final element = InspectorUtils.getElementFromRenderBox(
      boxInfo.targetRenderBox,
    );
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
                    "${element?.widget.toString() ?? 'Unknown'} | ${describeIdentity(boxInfo.targetRenderBox)}",
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
                _MainRow(boxInfo: boxInfo, theme: theme),
              ],
              // Compare button and comparison info
              _CompareSection(
                boxInfo: boxInfo,
                comparedBoxInfo: comparedBoxInfo,
                isCompareMode: isCompareMode,
                onEnterCompareMode: onEnterCompareMode,
                onExitCompareMode: onExitCompareMode,
                theme: theme,
              ),
              if (boxInfo.targetRenderBox is RenderParagraph) ...[
                Divider(
                  height: 16,
                  color: iSpect.theme.divider?.resolve(context),
                ),
                _RenderParagraphInfo(boxInfo: boxInfo, theme: theme),
              ],
              if (boxInfo.targetRenderBox is RenderDecoratedBox) ...[
                Divider(
                  height: 16,
                  color: iSpect.theme.divider?.resolve(context),
                ),
                _RenderDecoratedBoxInfo(boxInfo: boxInfo, theme: theme),
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
    required this.theme,
    this.iconColor,
    this.backgroundColor,
  });
  final IconData icon;
  final Widget child;
  final String subtitle;
  final ThemeData theme;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
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
    required this.theme,
  });
  final BoxInfo boxInfo;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _InfoRow(
            icon: Icons.format_shapes,
            subtitle: 'size',
            theme: theme,
            backgroundColor: theme.chipTheme.backgroundColor,
            child: Text(
              boxInfo.targetRect != null
                  ? '${boxInfo.targetRect!.width.toStringAsFixed(1)} × ${boxInfo.targetRect!.height}'
                  : 'n/a',
            ),
          ),
          _InfoRow(
            icon: Icons.straighten,
            subtitle: 'padding (LTRB)',
            theme: theme,
            backgroundColor: theme.chipTheme.backgroundColor,
            child: Text(boxInfo.describePadding() ?? 'n/a'),
          ),
        ],
      );
}

// --- Compare Section ---

class _CompareSection extends StatelessWidget {
  const _CompareSection({
    required this.boxInfo,
    required this.comparedBoxInfo,
    required this.isCompareMode,
    required this.onEnterCompareMode,
    required this.onExitCompareMode,
    required this.theme,
  });

  final BoxInfo boxInfo;
  final BoxInfo? comparedBoxInfo;
  final bool isCompareMode;
  final VoidCallback onEnterCompareMode;
  final VoidCallback onExitCompareMode;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              if (isCompareMode)
                _CompareButton(
                  theme: theme,
                  label: context.ispectL10n.cancelCompare,
                  icon: Icons.close,
                  color: theme.colorScheme.error,
                  onPressed: onExitCompareMode,
                )
              else
                _CompareButton(
                  theme: theme,
                  label: context.ispectL10n.compare,
                  icon: Icons.compare_arrows,
                  color: Colors.green.shade700,
                  onPressed: onEnterCompareMode,
                ),
              if (isCompareMode) ...[
                const SizedBox(width: 8),
                Text(
                  context.ispectL10n.tapWidgetToCompare,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          if (comparedBoxInfo != null) ...[
            const SizedBox(height: 8),
            _CompareDistanceRow(
              boxInfoA: boxInfo,
              boxInfoB: comparedBoxInfo!,
              theme: theme,
            ),
          ],
        ],
      );
}

class _CompareButton extends StatelessWidget {
  const _CompareButton({
    required this.theme,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final ThemeData theme;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          backgroundColor: color.withValues(alpha: .15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 14, color: color),
        label: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _CompareDistanceRow extends StatelessWidget {
  const _CompareDistanceRow({
    required this.boxInfoA,
    required this.boxInfoB,
    required this.theme,
  });

  final BoxInfo boxInfoA;
  final BoxInfo boxInfoB;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final from = boxInfoA.targetRect;
    final to = boxInfoB.targetRect;
    if (from == null || to == null) return const SizedBox.shrink();

    final comparedElement = InspectorUtils.getElementFromRenderBox(
      boxInfoB.targetRenderBox,
    );

    final distances = computeCompareDistances(from, to);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.ispectL10n.comparedWith}: ${comparedElement?.widget.runtimeType ?? 'Unknown'}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final d in distances)
              _InfoRow(
                icon: d.icon,
                subtitle: d.labelOf(context),
                theme: theme,
                iconColor: Colors.green.shade700,
                backgroundColor: Colors.green.withValues(alpha: .1),
                child: Text(d.value.toStringAsFixed(1)),
              ),
          ],
        ),
      ],
    );
  }
}

// --- Rich Text Inspection ---

class _RenderParagraphInfo extends StatelessWidget {
  const _RenderParagraphInfo({
    required this.boxInfo,
    required this.theme,
  });
  final BoxInfo boxInfo;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final targetBox = boxInfo.targetRenderBox;
    if (targetBox is! RenderParagraph) return const SizedBox.shrink();

    final spans = _extractSpanInfo(targetBox.text);

    if (spans.isEmpty) return const SizedBox.shrink();

    // If there's only one span (simple text), show flat style info
    if (spans.length == 1) {
      return _buildStyleRow(context, spans.first.style);
    }

    // Rich text: show each span with its text preview and styles
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < spans.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          if (spans[i].text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '"${_truncate(spans[i].text, 40)}"',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withValues(alpha: .6),
                ),
              ),
            ),
          _buildStyleRow(context, spans[i].style),
        ],
      ],
    );
  }

  Widget _buildStyleRow(BuildContext context, TextStyle? style) {
    if (style == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _InfoRow(
          icon: Icons.font_download,
          subtitle: 'font family',
          theme: theme,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.fontFamily ?? 'n/a'),
        ),
        _InfoRow(
          icon: Icons.format_size,
          subtitle: 'font size',
          theme: theme,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.fontSize?.toStringAsFixed(1) ?? 'n/a'),
        ),
        _InfoRow(
          icon: Icons.line_weight,
          subtitle: 'weight',
          theme: theme,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.fontWeight?.toString() ?? 'n/a'),
        ),
        _InfoRow(
          icon: Icons.color_lens,
          subtitle: 'color',
          theme: theme,
          iconColor: style.color,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(
            style.color != null
                ? colorToHexString(style.color!, withAlpha: true)
                : 'n/a',
            style: TextStyle(color: style.color),
          ),
        ),
        _InfoRow(
          icon: Icons.text_format,
          subtitle: 'decoration',
          theme: theme,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.decoration?.toString() ?? 'n/a'),
        ),
        _InfoRow(
          icon: Icons.height,
          subtitle: 'height',
          theme: theme,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.height?.toStringAsFixed(1) ?? 'n/a'),
        ),
        if (style.letterSpacing != null)
          _InfoRow(
            icon: Icons.space_bar,
            subtitle: 'letter spacing',
            theme: theme,
            backgroundColor: theme.chipTheme.backgroundColor,
            child: Text(style.letterSpacing!.toStringAsFixed(1)),
          ),
        if (style.wordSpacing != null)
          _InfoRow(
            icon: Icons.space_bar,
            subtitle: 'word spacing',
            theme: theme,
            backgroundColor: theme.chipTheme.backgroundColor,
            child: Text(style.wordSpacing!.toStringAsFixed(1)),
          ),
        if (style.fontStyle != null)
          _InfoRow(
            icon: Icons.format_italic,
            subtitle: 'font style',
            theme: theme,
            backgroundColor: theme.chipTheme.backgroundColor,
            child: Text(style.fontStyle!.name),
          ),
      ],
    );
  }

  String _truncate(String text, int maxLength) =>
      text.length > maxLength ? '${text.substring(0, maxLength)}…' : text;
}

// --- Decorated Box Inspection ---

class _RenderDecoratedBoxInfo extends StatelessWidget {
  const _RenderDecoratedBoxInfo({
    required this.boxInfo,
    required this.theme,
  });

  final BoxInfo boxInfo;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final targetBox = boxInfo.targetRenderBox;
    if (targetBox is! RenderDecoratedBox) return const SizedBox.shrink();

    final decoration = targetBox.decoration;
    if (decoration is! BoxDecoration) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (decoration.borderRadius != null)
          _InfoRow(
            icon: Icons.rounded_corner,
            subtitle: 'border radius',
            theme: theme,
            backgroundColor: theme.chipTheme.backgroundColor,
            child: Text(decoration.borderRadius.toString()),
          ),
        _InfoRow(
          icon: Icons.circle_outlined,
          subtitle: 'shape',
          theme: theme,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(decoration.shape.name),
        ),
        _InfoRow(
          icon: Icons.palette,
          subtitle: 'color',
          theme: theme,
          iconColor: decoration.color,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(
            decoration.color != null
                ? colorToHexString(decoration.color!, withAlpha: true)
                : 'n/a',
          ),
        ),
      ],
    );
  }
}

/// Extracted span info: text content + associated style.
class _SpanInfo {
  const _SpanInfo({required this.text, required this.style});
  final String text;
  final TextStyle? style;
}

/// Recursively extracts all [TextStyle] objects from an [InlineSpan] tree.
/// Returns a flat list of spans with their text and style.
List<_SpanInfo> _extractSpanInfo(InlineSpan span, [List<_SpanInfo>? result]) {
  result ??= [];

  if (span is TextSpan) {
    if (span.text != null && span.text!.isNotEmpty) {
      result.add(_SpanInfo(text: span.text!, style: span.style));
    }

    if (span.children != null) {
      for (final child in span.children!) {
        _extractSpanInfo(child, result);
      }
    }
  } else if (span is WidgetSpan) {
    result.add(const _SpanInfo(text: '[widget]', style: null));
  }

  return result;
}

// --- Figma-style compare distances ---

/// A single distance measurement to display.
class CompareDistance {
  const CompareDistance({
    required this.side,
    required this.value,
    required this.icon,
    required this.startOffset,
    required this.endOffset,
    required this.isHorizontal,
  });

  final CompareSide side;
  final double value;
  final IconData icon;

  /// Start and end positions for drawing the overlay line.
  final Offset startOffset;
  final Offset endOffset;
  final bool isHorizontal;

  String labelOf(BuildContext context) => switch (side) {
        CompareSide.left => context.ispectL10n.distanceLeft,
        CompareSide.top => context.ispectL10n.distanceTop,
        CompareSide.right => context.ispectL10n.distanceRight,
        CompareSide.bottom => context.ispectL10n.distanceBottom,
      };
}

enum CompareSide { left, top, right, bottom }

/// Computes Figma-style distances between two rects.
///
/// - **Separated on one axis**: shows only the gap on that axis.
/// - **Separated on both axes**: shows both gaps.
/// - **Overlapping on both axes**: shows LTRB edge alignment distances.
List<CompareDistance> computeCompareDistances(Rect from, Rect to) {
  final hSeparated = from.right <= to.left || to.right <= from.left;
  final vSeparated = from.bottom <= to.top || to.bottom <= from.top;

  final results = <CompareDistance>[];

  if (hSeparated) {
    // Horizontal gap line at FROM's vertical center
    final y = from.center.dy;
    if (from.right <= to.left) {
      results.add(
        CompareDistance(
          side: CompareSide.right,
          value: to.left - from.right,
          icon: Icons.arrow_forward,
          startOffset: Offset(from.right, y),
          endOffset: Offset(to.left, y),
          isHorizontal: true,
        ),
      );
    } else {
      results.add(
        CompareDistance(
          side: CompareSide.left,
          value: from.left - to.right,
          icon: Icons.arrow_back,
          startOffset: Offset(to.right, y),
          endOffset: Offset(from.left, y),
          isHorizontal: true,
        ),
      );
    }
  }

  if (vSeparated) {
    // Vertical gap line at TO's horizontal center
    final x = to.center.dx;
    if (from.bottom <= to.top) {
      results.add(
        CompareDistance(
          side: CompareSide.bottom,
          value: to.top - from.bottom,
          icon: Icons.arrow_downward,
          startOffset: Offset(x, from.bottom),
          endOffset: Offset(x, to.top),
          isHorizontal: false,
        ),
      );
    } else {
      results.add(
        CompareDistance(
          side: CompareSide.top,
          value: from.top - to.bottom,
          icon: Icons.arrow_upward,
          startOffset: Offset(x, to.bottom),
          endOffset: Offset(x, from.top),
          isHorizontal: false,
        ),
      );
    }
  }

  // Overlapping on both axes → show LTRB alignment
  if (!hSeparated && !vSeparated) {
    final left = (from.left - to.left).abs();
    final right = (from.right - to.right).abs();
    final top = (from.top - to.top).abs();
    final bottom = (from.bottom - to.bottom).abs();

    final midY = (from.center.dy + to.center.dy) / 2;
    final midX = (from.center.dx + to.center.dx) / 2;

    if (left > 0.5) {
      final minL = from.left < to.left ? from.left : to.left;
      final maxL = from.left > to.left ? from.left : to.left;
      results.add(
        CompareDistance(
          side: CompareSide.left,
          value: left,
          icon: Icons.arrow_back,
          startOffset: Offset(minL, midY - 6),
          endOffset: Offset(maxL, midY - 6),
          isHorizontal: true,
        ),
      );
    }
    if (right > 0.5) {
      final minR = from.right < to.right ? from.right : to.right;
      final maxR = from.right > to.right ? from.right : to.right;
      results.add(
        CompareDistance(
          side: CompareSide.right,
          value: right,
          icon: Icons.arrow_forward,
          startOffset: Offset(minR, midY + 6),
          endOffset: Offset(maxR, midY + 6),
          isHorizontal: true,
        ),
      );
    }
    if (top > 0.5) {
      final minT = from.top < to.top ? from.top : to.top;
      final maxT = from.top > to.top ? from.top : to.top;
      results.add(
        CompareDistance(
          side: CompareSide.top,
          value: top,
          icon: Icons.arrow_upward,
          startOffset: Offset(midX - 6, minT),
          endOffset: Offset(midX - 6, maxT),
          isHorizontal: false,
        ),
      );
    }
    if (bottom > 0.5) {
      final minB = from.bottom < to.bottom ? from.bottom : to.bottom;
      final maxB = from.bottom > to.bottom ? from.bottom : to.bottom;
      results.add(
        CompareDistance(
          side: CompareSide.bottom,
          value: bottom,
          icon: Icons.arrow_downward,
          startOffset: Offset(midX + 6, minB),
          endOffset: Offset(midX + 6, maxB),
          isHorizontal: false,
        ),
      );
    }
  }

  return results;
}
