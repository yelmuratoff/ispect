import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ispect_layout/src/number_format.dart';
import 'package:ispect_layout/src/widgets/components/property_extractors.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';
import 'package:ispect_layout/src/widgets/inspector/box_info.dart';
import 'package:ispect_layout/src/widgets/inspector/compare_distances.dart';
import 'package:ispect_layout/src/widgets/inspector/render_box_extension.dart';

class BoxInfoPanelWidget extends StatelessWidget {
  const BoxInfoPanelWidget({
    super.key,
    required this.boxInfo,
    required this.decimalPlaces,
    this.comparedBoxInfo,
    this.onCompare,
    this.isCompareActive = false,
  });

  final BoxInfo boxInfo;
  final int decimalPlaces;
  final BoxInfo? comparedBoxInfo;
  final VoidCallback? onCompare;
  final bool isCompareActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = boxInfo.targetRenderBox;
    final dividerColor = theme.colorScheme.outlineVariant;
    final hasCompare =
        target.attached && comparedBoxInfo?.targetRenderBox.attached == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            title: _PanelTitleBar(
              target: target,
              decimalPlaces: decimalPlaces,
              onCompare: onCompare,
              isCompareActive: isCompareActive,
            ),
            childrenPadding: const EdgeInsets.only(
              left: 12.0,
              right: 12.0,
              bottom: 12.0,
            ),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: _buildSections(context, target, dividerColor, hasCompare),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    RenderBox target,
    Color dividerColor,
    bool hasCompare,
  ) {
    final out = <Widget>[];
    void divider() => out.add(Divider(height: 20.0, color: dividerColor));

    // LAYOUT: size, padding, constraints.
    out
      ..add(const _SectionHeader('layout'))
      ..add(_MainRow(boxInfo: boxInfo, decimalPlaces: decimalPlaces))
      ..add(const SizedBox(height: 8))
      ..add(
        PropSection(
          props: constraintsProps(
            target.constraints,
            decimalPlaces: decimalPlaces,
          ),
        ),
      );

    if (hasCompare) {
      divider();
      out
        ..add(const _SectionHeader('compare'))
        ..add(
          _ComparedRow(
            boxInfo: boxInfo,
            comparedBoxInfo: comparedBoxInfo!,
            decimalPlaces: decimalPlaces,
          ),
        );
    }

    if (target is RenderParagraph) {
      out.addAll(_paragraphSections(context, target, dividerColor));
    } else {
      final tProps = typeProps(target, decimalPlaces: decimalPlaces);
      if (tProps.isNotEmpty) {
        divider();
        out
          ..add(const _SectionHeader('type'))
          ..add(PropSection(props: tProps));
      }
      final dProps = _resolvedDecorationProps();
      if (dProps.isNotEmpty) {
        divider();
        out
          ..add(const _SectionHeader('appearance'))
          ..add(PropSection(props: dProps));
      }
    }

    out.addAll(_wrapperSections(context, dividerColor));
    return out;
  }

  List<Widget> _paragraphSections(
    BuildContext context,
    RenderParagraph target,
    Color dividerColor,
  ) {
    final theme = Theme.of(context);
    final preview = previewText(target.text);
    final pProps = paragraphProps(target, decimalPlaces: decimalPlaces);
    final spanSections = extractTextStyles(target.text)
        .map((style) => spanProps(style, decimalPlaces: decimalPlaces))
        .where((p) => p.isNotEmpty)
        .toList();

    final out = <Widget>[];
    if (preview.isNotEmpty || pProps.isNotEmpty) {
      out
        ..add(Divider(height: 20.0, color: dividerColor))
        ..add(const _SectionHeader('text'));
      if (preview.isNotEmpty) {
        out.add(
          PropChip(
            icon: Icons.text_snippet_outlined,
            subtitle: 'text',
            backgroundColor: theme.chipTheme.backgroundColor,
            expandChild: true,
            child: Text(
              '"$preview"',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
        if (pProps.isNotEmpty) out.add(const SizedBox(height: 6));
      }
      if (pProps.isNotEmpty) {
        out.add(PropSection(props: pProps));
      }
    }

    if (spanSections.isNotEmpty) {
      out
        ..add(Divider(height: 20.0, color: dividerColor))
        ..add(const _SectionHeader('typography'));
      for (var i = 0; i < spanSections.length; i++) {
        if (i > 0) out.add(const SizedBox(height: 6));
        out.add(PropSection(props: spanSections[i]));
      }
    }
    return out;
  }

  List<Widget> _wrapperSections(BuildContext context, Color dividerColor) {
    final theme = Theme.of(context);
    final wrappers = _wrappersWithTypeProps();
    if (wrappers.isEmpty) return const [];
    return [
      for (final box in wrappers) ...[
        Divider(height: 20.0, color: dividerColor),
        const _SectionHeader('wrapper'),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            describeIdentity(box),
            style: theme.textTheme.bodySmall,
          ),
        ),
        PropSection(props: typeProps(box, decimalPlaces: decimalPlaces)),
      ],
    ];
  }

  /// Decoration resolved from the hit-test path. Prefers [ColoredBox] color
  /// over [BoxDecoration] to avoid duplication when a ColoredBox wraps a
  /// decorated child.
  List<PropSpec> _resolvedDecorationProps() {
    final coloredBoxColor = boxInfo.coloredBoxColor;
    if (coloredBoxColor != null) {
      return [
        (
          icon: Icons.palette,
          subtitle: 'color',
          child: ColorHexChip(coloredBoxColor),
        ),
      ];
    }
    if (boxInfo.decoratedBoxForDisplay?.decoration case final BoxDecoration d) {
      return decorationProps(d, decimalPlaces: decimalPlaces);
    }
    return [];
  }

  /// Walks the parent chain, collecting render boxes that share the target's
  /// paint size and carry type-specific props. Stops at the first size
  /// mismatch — wrappers further up apply to a different bounding box, so
  /// surfacing them here would mislead about what the displayed size
  /// actually represents.
  List<RenderBox> _wrappersWithTypeProps() {
    final target = boxInfo.targetRenderBox;
    final result = <RenderBox>[];
    var current = target.parent;
    while (current is RenderBox && current.size == target.size) {
      if (hasTypeProps(current)) result.add(current);
      current = current.parent;
    }
    return result;
  }
}

// ─── Private widgets ─────────────────────────────────────────────────────────

class _PanelTitleBar extends StatelessWidget {
  const _PanelTitleBar({
    required this.target,
    required this.decimalPlaces,
    required this.onCompare,
    required this.isCompareActive,
  });

  final RenderBox target;
  final int decimalPlaces;
  final VoidCallback? onCompare;
  final bool isCompareActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = target.displaySize;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                describeIdentity(target),
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                formatInspectorSize(size, decimalPlaces: decimalPlaces),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onCompare != null)
          IconButton(
            iconSize: 18.0,
            color: isCompareActive
                ? theme.colorScheme.primary
                : theme.iconTheme.color,
            onPressed: onCompare,
            icon: const Icon(Icons.compare),
          ),
        IconButton(
          iconSize: 18.0,
          onPressed: () => Clipboard.setData(
            ClipboardData(text: target.toStringDeep()),
          ),
          icon: const Icon(Icons.copy),
        ),
      ],
    );
  }
}

class _MainRow extends StatelessWidget {
  const _MainRow({required this.boxInfo, required this.decimalPlaces});
  final BoxInfo boxInfo;
  final int decimalPlaces;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displaySize = boxInfo.targetRenderBox.displaySize;
    final bg = theme.chipTheme.backgroundColor;
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        PropChip(
          icon: Icons.format_shapes,
          subtitle: 'size',
          backgroundColor: bg,
          child: Text(
            formatInspectorSize(displaySize, decimalPlaces: decimalPlaces),
          ),
        ),
        if (boxInfo.containerRect != null && !boxInfo.isContainerFlex)
          PropChip(
            icon: Icons.straighten,
            subtitle: 'padding (LTRB)',
            backgroundColor: bg,
            child: Text(
              boxInfo.describeOriginalPadding(decimalPlaces: decimalPlaces),
            ),
          ),
      ],
    );
  }
}

class _ComparedRow extends StatelessWidget {
  const _ComparedRow({
    required this.boxInfo,
    required this.comparedBoxInfo,
    required this.decimalPlaces,
  });

  final BoxInfo boxInfo;
  final BoxInfo comparedBoxInfo;
  final int decimalPlaces;

  @override
  Widget build(BuildContext context) {
    final originalWidth = boxInfo.targetRenderBox.size.width;
    final scale =
        originalWidth > 0 ? boxInfo.targetRect.width / originalWidth : 1.0;
    final distances = computeCompareDistances(
      boxInfo.targetRect,
      comparedBoxInfo.targetRect,
      scale: scale,
    );
    return PropSection(
      props: [
        for (final d in distances)
          (
            icon: d.icon,
            subtitle: d.side.name,
            child: Text(
              formatInspectorDouble(d.value, decimalPlaces: decimalPlaces),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 0.8,
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
