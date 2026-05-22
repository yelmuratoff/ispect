import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect_layout/src/number_format.dart';
import 'package:ispect_layout/src/widgets/color_picker/utils.dart';
import 'package:ispect_layout/src/widgets/components/property_extractors.dart'
    show describeAlignment;
import 'package:ispect_layout/src/widgets/components/value_descriptors.dart'
    show formatRadius;

/// Declarative spec for a single info chip; rendered by [PropSection].
typedef PropSpec = ({IconData icon, String subtitle, Widget child});

// ─── Primitives ──────────────────────────────────────────────────────────────

/// Circular color swatch used inline in info chips.
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.18),
            width: 1.0,
          ),
        ),
      );
}

/// Color dot + hex label. Tapping copies the hex value to the clipboard.
///
/// Named with a `Chip` suffix to avoid colliding with Flutter's
/// [ColorSwatch] generic palette type from `material.dart`.
class ColorHexChip extends StatelessWidget {
  const ColorHexChip(this.color, {super.key});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = '#${colorToHexString(color, withAlpha: true)}';
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: hex));
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              spacing: 8,
              children: [ColorDot(color), Text('Copied $hex')],
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6.0,
        children: [
          ColorDot(color),
          Text(
            hex,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Text that truncates with ellipsis when it would outgrow its chip.
///
/// Used for values of potentially unbounded length (URLs, `toString()` dumps
/// of ImageFilter/ColorFilter, Offset/Alignment representations).
class EllipsizedText extends StatelessWidget {
  const EllipsizedText(this.value, {super.key});
  final String value;

  @override
  Widget build(BuildContext context) => Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      );
}

// ─── Chip + section ──────────────────────────────────────────────────────────

/// Single labelled info chip: leading icon, value, subtitle.
///
/// [expandChild] controls sizing:
/// - `false` (default) — chip shrink-wraps to its content and lives inside a
///   [PropSection] (a [Wrap] of chips capped at 260 px each).
/// - `true` — chip takes the full available width, used for wide preview rows
///   like paragraph text previews.
class PropChip extends StatelessWidget {
  const PropChip({
    super.key,
    required this.icon,
    required this.subtitle,
    required this.child,
    this.iconColor,
    this.backgroundColor,
    this.expandChild = false,
  });

  final IconData icon;
  final String subtitle;
  final Widget child;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10.0,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
    Widget content = Row(
      mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(
            icon,
            size: 20.0,
            color: iconColor ?? theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(width: 12.0),
        if (expandChild)
          Expanded(child: column)
        else
          // Cap column width so long child text honours maxLines/ellipsis
          // instead of forcing the whole chip past the parent ConstrainedBox.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 208),
            child: column,
          ),
      ],
    );
    if (backgroundColor != null) {
      content = Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: content,
      );
    }
    return content;
  }
}

/// A [Wrap] of [PropChip]s. Each chip is capped at 260 px so the row never
/// overflows the panel on narrow screens.
class PropSection extends StatelessWidget {
  const PropSection({super.key, required this.props});
  final List<PropSpec> props;

  @override
  Widget build(BuildContext context) {
    if (props.isEmpty) return const SizedBox.shrink();
    final bg = Theme.of(context).colorScheme.surfaceContainerLow;
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        for (final p in props)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: PropChip(
              icon: p.icon,
              subtitle: p.subtitle,
              backgroundColor: bg,
              child: p.child,
            ),
          ),
      ],
    );
  }
}

// ─── Composite chip contents ─────────────────────────────────────────────────

/// Muted `x:` / `y:` labels with tabular values for an offset or translation.
class OffsetValue extends StatelessWidget {
  const OffsetValue({super.key, required this.dx, required this.dy});

  final String dx;
  final String dy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final labelStyle = valueStyle?.copyWith(
      fontSize: 10.0,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [Text('x:', style: labelStyle), Text(dx, style: valueStyle)],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [Text('y:', style: labelStyle), Text(dy, style: valueStyle)],
        ),
      ],
    );
  }
}

/// Color swatch + muted `width:` label + value for a single border side.
class BorderSideValue extends StatelessWidget {
  const BorderSideValue({
    super.key,
    required this.color,
    required this.width,
  });

  final Color color;
  final String width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final labelStyle = valueStyle?.copyWith(
      fontSize: 10.0,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        ColorHexChip(color),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text('width:', style: labelStyle),
            Text(width, style: valueStyle),
          ],
        ),
      ],
    );
  }
}

/// Visual list of [BoxShadow]s: color swatch + blur/spread/offset/blurStyle.
class ShadowsView extends StatelessWidget {
  const ShadowsView(this.shadows, {super.key, this.decimalPlaces = 1});
  final List<BoxShadow> shadows;
  final int decimalPlaces;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final separatorColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final labelStyle = valueStyle?.copyWith(
      fontSize: 10.0,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
    );

    String f(double v) =>
        formatInspectorDouble(v, decimalPlaces: decimalPlaces);

    Widget kv(String label, String value) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(label, style: labelStyle),
            Text(value, style: valueStyle),
          ],
        );

    final items = <Widget>[];
    for (var i = 0; i < shadows.length; i++) {
      if (i > 0) {
        items.add(Divider(height: 6, thickness: 0.5, color: separatorColor));
      }
      final s = shadows[i];
      items.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            ColorHexChip(s.color),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                kv('blur:', f(s.blurRadius)),
                if (s.spreadRadius != 0) kv('spread:', f(s.spreadRadius)),
                if (s.blurStyle != BlurStyle.normal)
                  kv('style:', s.blurStyle.name),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                kv('x:', f(s.offset.dx)),
                kv('y:', f(s.offset.dy)),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}

/// Visual preview strip of a [Gradient].
class GradientPreview extends StatelessWidget {
  const GradientPreview(this.gradient, {super.key});
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 14,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      );
}

/// Full gradient breakdown: preview, type label, color stops, and
/// shape-specific details (begin/end, center/radius, angles).
class GradientView extends StatelessWidget {
  const GradientView(this.gradient, {super.key, this.decimalPlaces = 1});
  final Gradient gradient;
  final int decimalPlaces;

  @override
  Widget build(BuildContext context) {
    final g = gradient;
    final type = switch (g) {
      LinearGradient() => 'linear',
      RadialGradient() => 'radial',
      SweepGradient() => 'sweep',
      _ => g.runtimeType.toString(),
    };

    final stops = g.stops;
    final detail = switch (g) {
      LinearGradient(:final begin, :final end, :final tileMode) => [
          'begin:${describeAlignment(begin)}',
          'end:${describeAlignment(end)}',
          if (tileMode != TileMode.clamp) 'tile:${tileMode.name}',
        ],
      RadialGradient(:final center, :final radius, :final tileMode) => [
          'center:${describeAlignment(center)}',
          'r:${formatInspectorDouble(radius, decimalPlaces: decimalPlaces)}',
          if (tileMode != TileMode.clamp) 'tile:${tileMode.name}',
        ],
      SweepGradient(
        :final center,
        :final startAngle,
        :final endAngle,
        :final tileMode,
      ) =>
        [
          'center:${describeAlignment(center)}',
          'start:${formatInspectorDouble(startAngle, decimalPlaces: decimalPlaces)}',
          'end:${formatInspectorDouble(endAngle, decimalPlaces: decimalPlaces)}',
          if (tileMode != TileMode.clamp) 'tile:${tileMode.name}',
        ],
      _ => <String>[],
    };

    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final labelStyle = valueStyle?.copyWith(
      fontSize: 10.0,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
    );

    Widget kv(String label, String value) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(label, style: labelStyle),
            Text(value, style: valueStyle),
          ],
        );

    // Split 'key:value' detail strings into muted label + normal value.
    Widget detailRow(String entry) {
      final idx = entry.indexOf(':');
      if (idx < 0) return Text(entry, style: valueStyle);
      return kv('${entry.substring(0, idx)}:', entry.substring(idx + 1));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [GradientPreview(g), Text(type)],
        ),
        for (var i = 0; i < g.colors.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              ColorHexChip(g.colors[i]),
              if (stops != null && i < stops.length)
                kv(
                  '@',
                  formatInspectorDouble(
                    stops[i],
                    decimalPlaces: decimalPlaces,
                  ),
                ),
            ],
          ),
        for (final d in detail) detailRow(d),
      ],
    );
  }
}

// ─── Border radius ────────────────────────────────────────────────────────────

/// Returns a [Text] for uniform radii or a [BorderRadiusGrid] for asymmetric.
Widget buildBorderRadiusChild(
  BorderRadiusGeometry geometry, {
  int decimalPlaces = 1,
}) {
  final r = geometry.resolve(TextDirection.ltr);
  final corners = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
  if (corners.every((c) => c == corners.first)) {
    return Text(formatRadius(corners.first, decimalPlaces: decimalPlaces));
  }
  return BorderRadiusGrid(
    topLeft: r.topLeft,
    topRight: r.topRight,
    bottomRight: r.bottomRight,
    bottomLeft: r.bottomLeft,
    decimalPlaces: decimalPlaces,
  );
}

/// Compact 2×2 grid showing TL/TR/BR/BL corner radii.
class BorderRadiusGrid extends StatelessWidget {
  const BorderRadiusGrid({
    super.key,
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    this.decimalPlaces = 1,
  });

  final Radius topLeft;
  final Radius topRight;
  final Radius bottomRight;
  final Radius bottomLeft;
  final int decimalPlaces;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final labelStyle = valueStyle?.copyWith(
      fontSize: 10.0,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
    );
    String f(Radius r) => formatRadius(r, decimalPlaces: decimalPlaces);

    Widget cell(String label, Radius r) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(label, style: labelStyle),
            Text(f(r), style: valueStyle),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [cell('TL', topLeft), cell('TR', topRight)],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [cell('BL', bottomLeft), cell('BR', bottomRight)],
        ),
      ],
    );
  }
}
