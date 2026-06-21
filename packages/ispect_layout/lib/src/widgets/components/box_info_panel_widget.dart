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
import 'package:ispect_layout/src/widgets/squircle.dart';

class BoxInfoPanelWidget extends StatefulWidget {
  const BoxInfoPanelWidget({
    super.key,
    required this.boxInfo,
    required this.decimalPlaces,
    this.comparedBoxInfo,
    this.onCompare,
    this.isCompareActive = false,
    this.onSelectFromPath,
  });

  final BoxInfo boxInfo;
  final int decimalPlaces;
  final BoxInfo? comparedBoxInfo;
  final VoidCallback? onCompare;
  final bool isCompareActive;
  final void Function(RenderBox box)? onSelectFromPath;

  @override
  State<BoxInfoPanelWidget> createState() => _BoxInfoPanelWidgetState();
}

class _BoxInfoPanelWidgetState extends State<BoxInfoPanelWidget> {
  bool _isExpanded = false;

  // Inside the inspector overlay Theme.of(context) is the host app's
  // ColorScheme; an owned dark, blue-accented scheme keeps the panel in
  // ISpect's design language instead of inheriting a stray host accent.
  static const ColorScheme _ownedScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF3B82F6),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1F3658),
    onPrimaryContainer: Color(0xFFCFE0FF),
    secondary: Color(0xFF3B82F6),
    onSecondary: Colors.white,
    error: Color(0xFFFF6B6B),
    onError: Colors.white,
    surface: Color(0xFF1B1B1F),
    onSurface: Color(0xFFF5F5F7),
    surfaceContainerHighest: Color(0xFF26262B),
    onSurfaceVariant: Color(0xFFAFAFB8),
    outlineVariant: Color(0xFF3A3A40),
  );

  static final ThemeData _panelTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _ownedScheme,
  );

  @override
  Widget build(BuildContext context) => Theme(
        data: _panelTheme,
        child: Builder(builder: _buildPanel),
      );

  Widget _buildPanel(BuildContext context) {
    final theme = Theme.of(context);
    final target = widget.boxInfo.targetRenderBox;
    final dividerColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.4);
    final hasCompare = target.attached &&
        widget.comparedBoxInfo?.targetRenderBox.attached == true;
    final breadcrumb = _buildBreadcrumb();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      shape: InspectorSquircle.border(
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PanelTitleBar(
                          target: target,
                          decimalPlaces: widget.decimalPlaces,
                          onCompare: widget.onCompare,
                          isCompareActive: widget.isCompareActive,
                        ),
                        if (breadcrumb != null) breadcrumb,
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTrailing(theme),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children:
                      _buildSections(context, target, dividerColor, hasCompare),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrailing(ThemeData theme) => AnimatedRotation(
        turns: _isExpanded ? 0.5 : 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Container(
          width: 28,
          height: 28,
          decoration: InspectorSquircle.decoration(
            color: theme.colorScheme.surfaceContainerHighest,
            radius: 8,
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );

  /// The breadcrumb only earns space when there is somewhere to navigate to —
  /// a single meaningful entry means the chips would just echo the title.
  Widget? _buildBreadcrumb() {
    final onSelect = widget.onSelectFromPath;
    if (onSelect == null) return null;
    final path = widget.boxInfo.meaningfulPath;
    if (path.length < 2) return null;
    return _HitTestBreadcrumb(
      path: path,
      currentTarget: widget.boxInfo.targetRenderBox,
      onSelect: onSelect,
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
      ..add(
        _MainRow(
          boxInfo: widget.boxInfo,
          decimalPlaces: widget.decimalPlaces,
        ),
      )
      ..add(const SizedBox(height: 8))
      ..add(
        PropSection(
          props: constraintsProps(
            target.constraints,
            decimalPlaces: widget.decimalPlaces,
          ),
        ),
      );

    if (hasCompare) {
      divider();
      out
        ..add(const _SectionHeader('compare'))
        ..add(
          _ComparedRow(
            boxInfo: widget.boxInfo,
            comparedBoxInfo: widget.comparedBoxInfo!,
            decimalPlaces: widget.decimalPlaces,
          ),
        );
    }

    if (target is RenderParagraph) {
      out.addAll(_paragraphSections(context, target, dividerColor));
    } else {
      final tProps = typeProps(target, decimalPlaces: widget.decimalPlaces);
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
      final svgWidget = resolveSvgPicture(target);
      if (svgWidget != null) {
        final sProps = svgProps(svgWidget, decimalPlaces: widget.decimalPlaces);
        if (sProps.isNotEmpty) {
          divider();
          out
            ..add(const _SectionHeader('svg'))
            ..add(PropSection(props: sProps));
        }
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
    final chipBg = theme.colorScheme.surfaceContainerLow;
    final iconGlyphs = describeAsIconGlyphs(target.text);
    final pProps = paragraphProps(target, decimalPlaces: widget.decimalPlaces);
    final spanSections = extractSpanStyleGroups(target.text)
        .map(
          (g) => (
            props: spanProps(g.style, decimalPlaces: widget.decimalPlaces),
            preview: g.textPreview,
          ),
        )
        .where((e) => e.props.isNotEmpty)
        .toList();

    final out = <Widget>[];

    if (iconGlyphs != null) {
      out
        ..add(Divider(height: 20.0, color: dividerColor))
        ..add(const _SectionHeader('icon'))
        ..add(_IconGlyphPreview(glyphs: iconGlyphs, chipBg: chipBg));
      if (pProps.isNotEmpty) {
        out
          ..add(const SizedBox(height: 6))
          ..add(PropSection(props: pProps));
      }
    } else {
      final preview = previewText(target.text);
      if (preview.isNotEmpty || pProps.isNotEmpty) {
        out
          ..add(Divider(height: 20.0, color: dividerColor))
          ..add(const _SectionHeader('text'));
        if (preview.isNotEmpty) {
          out.add(
            PropChip(
              icon: Icons.text_snippet_outlined,
              subtitle: 'text',
              backgroundColor: chipBg,
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
    }

    if (spanSections.isNotEmpty) {
      out
        ..add(Divider(height: 20.0, color: dividerColor))
        ..add(const _SectionHeader('typography'));

      final multiSpan = spanSections.length > 1;
      for (var i = 0; i < spanSections.length; i++) {
        final entry = spanSections[i];
        if (i > 0) {
          out.add(Divider(height: 12, thickness: 0.5, color: dividerColor));
        }
        if (multiSpan && entry.preview != null) {
          out.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '"${entry.preview}"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.55),
                ),
              ),
            ),
          );
        }
        out.add(PropSection(props: entry.props));
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
            _describeIdentity(box),
            style: theme.textTheme.bodySmall,
          ),
        ),
        PropSection(
          props: typeProps(box, decimalPlaces: widget.decimalPlaces),
        ),
      ],
    ];
  }

  /// Decoration resolved from the hit-test path. Prefers [ColoredBox] color
  /// over [BoxDecoration] to avoid duplication when a ColoredBox wraps a
  /// decorated child.
  List<PropSpec> _resolvedDecorationProps() {
    final coloredBoxColor = widget.boxInfo.coloredBoxColor;
    if (coloredBoxColor != null) {
      return [
        (
          icon: Icons.palette,
          subtitle: 'color',
          child: ColorHexChip(coloredBoxColor),
        ),
      ];
    }
    if (widget.boxInfo.decoratedBoxForDisplay?.decoration
        case final BoxDecoration d) {
      return decorationProps(d, decimalPlaces: widget.decimalPlaces);
    }
    return [];
  }

  /// Walks the parent chain, collecting render boxes that share the target's
  /// paint size and carry type-specific props. Stops at the first size
  /// mismatch — wrappers further up apply to a different bounding box, so
  /// surfacing them here would mislead about what the displayed size
  /// actually represents.
  List<RenderBox> _wrappersWithTypeProps() {
    final target = widget.boxInfo.targetRenderBox;
    final result = <RenderBox>[];
    var current = target.parent;
    while (current is RenderBox && current.size == target.size) {
      if (hasTypeProps(current)) result.add(current);
      current = current.parent;
    }
    return result;
  }
}

/// Flutter's [describeIdentity] returns `<optimized out>#hash` in release
/// because `objectRuntimeType` falls back to a hardcoded literal there.
/// Reading `runtimeType` directly survives release (without `--obfuscate`).
String _describeIdentity(Object? object) =>
    '${object.runtimeType}#${shortHash(object)}';

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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _shortTypeName(target),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    ' #${shortHash(target)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.45),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
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
        if (onCompare != null) ...[
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16.0,
              style: IconButton.styleFrom(
                backgroundColor: isCompareActive
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                foregroundColor: isCompareActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                shape: InspectorSquircle.border(radius: 8),
              ),
              onPressed: onCompare,
              icon: const Icon(Icons.compare),
            ),
          ),
        ],
        const SizedBox(width: 4),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 16.0,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              shape: InspectorSquircle.border(radius: 8),
            ),
            onPressed: () => _copyRenderTreeToClipboard(context, target),
            icon: const Icon(Icons.copy_rounded),
          ),
        ),
      ],
    );
  }

  static String _shortTypeName(Object obj) {
    final name = obj.runtimeType.toString();
    return name.startsWith('Render') ? name.substring(6) : name;
  }

  static const int _maxClipboardChars = 10000;

  Future<void> _copyRenderTreeToClipboard(
    BuildContext context,
    RenderBox target,
  ) async {
    final full = target.toStringDeep();
    final truncated = full.length > _maxClipboardChars
        ? '${full.substring(0, _maxClipboardChars)}\n… (${full.length - _maxClipboardChars} more chars)'
        : full;

    await Clipboard.setData(ClipboardData(text: truncated));

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            full.length > _maxClipboardChars
                ? 'Copied render tree ($_maxClipboardChars / ${full.length} chars)'
                : 'Copied render tree (${full.length} chars)',
          ),
        ),
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
    final bg = theme.colorScheme.surfaceContainerLow;
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
            subtitle: 'padding',
            backgroundColor: bg,
            child: _PaddingBoxModel(
              padding: boxInfo.originalPadding,
              decimalPlaces: decimalPlaces,
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

/// Renders the inspected icon glyph next to its `U+XXXX` code point.
///
/// Release builds with `--tree-shake-icons` (default) may render a glyph
/// the host app never references statically as tofu — the adjacent code
/// point keeps the row readable. Build with `--no-tree-shake-icons` if
/// faithful glyph rendering matters in release.
class _IconGlyphPreview extends StatelessWidget {
  const _IconGlyphPreview({required this.glyphs, required this.chipBg});

  final IconGlyphPreview glyphs;
  final Color chipBg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PropChip(
      icon: Icons.emoji_symbols_outlined,
      subtitle: 'icon · ${glyphs.fontFamily}',
      backgroundColor: chipBg,
      expandChild: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            glyphs.glyphs,
            style: TextStyle(
              fontFamily: glyphs.fontFamily,
              fontSize: 22.0,
              color: theme.colorScheme.onSurface,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 10.0),
          Flexible(
            child: Text(
              glyphs.codePointsLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact 2×2 grid showing T/R/B/L padding values.
///
/// Renders two rows (T R / B L) so the chip stays narrow
/// even when values are three or more digits.
class _PaddingBoxModel extends StatelessWidget {
  const _PaddingBoxModel({required this.padding, required this.decimalPlaces});
  final EdgeInsets padding;
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
    String f(double v) =>
        formatInspectorDouble(v, decimalPlaces: decimalPlaces);

    Widget cell(String label, double v) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(label, style: labelStyle),
            Text(f(v), style: valueStyle),
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
          children: [cell('T', padding.top), cell('B', padding.bottom)],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [cell('L', padding.left), cell('R', padding.right)],
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
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: InspectorSquircle.decoration(
          color: theme.colorScheme.primaryContainer,
          radius: 6,
        ),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.0,
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Horizontal hit-test breadcrumb. Outer→inner chain of meaningful render
/// boxes under the pointer, with the currently selected one highlighted.
/// Tapping a chip swaps the active selection without re-running hit-test.
class _HitTestBreadcrumb extends StatefulWidget {
  const _HitTestBreadcrumb({
    required this.path,
    required this.currentTarget,
    required this.onSelect,
  });

  final List<RenderBox> path;
  final RenderBox currentTarget;
  final void Function(RenderBox box) onSelect;

  @override
  State<_HitTestBreadcrumb> createState() => _HitTestBreadcrumbState();
}

class _HitTestBreadcrumbState extends State<_HitTestBreadcrumb> {
  final ScrollController _scrollController = ScrollController();
  final Map<RenderBox, GlobalKey> _chipKeys = <RenderBox, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _scheduleScrollToSelected();
  }

  @override
  void didUpdateWidget(covariant _HitTestBreadcrumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleScrollToSelected();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(RenderBox box) => _chipKeys.putIfAbsent(box, GlobalKey.new);

  void _scheduleScrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _chipKeys[widget.currentTarget]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Drop keys for boxes no longer in the path so the map can't grow without
    // bound across selections.
    final inPath = Set<RenderBox>.identity()..addAll(widget.path);
    _chipKeys.removeWhere((box, _) => !inPath.contains(box));

    final theme = Theme.of(context);
    final separatorColor =
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    final children = <Widget>[];
    for (var i = 0; i < widget.path.length; i++) {
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Icon(
            Icons.chevron_right,
            size: 14.0,
            color: separatorColor,
          ),
        ));
      }
      final box = widget.path[i];
      children.add(_BreadcrumbChip(
        key: _keyFor(box),
        box: box,
        isSelected: identical(box, widget.currentTarget),
        onTap: () => widget.onSelect(box),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: SizedBox(
        height: 26.0,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({
    super.key,
    required this.box,
    required this.isSelected,
    required this.onTap,
  });

  final RenderBox box;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.16)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final foreground = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Material(
      color: background,
      shape: InspectorSquircle.border(radius: 6),
      child: InkWell(
        customBorder: InspectorSquircle.border(radius: 6),
        onTap: isSelected ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: Text(
            _shortTypeLabel(box),
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  /// Renders `RenderFlex` as `Flex`, `RenderDecoratedBox` as `DecoratedBox`,
  /// and so on. Saves horizontal space in a deeply nested chain.
  static String _shortTypeLabel(RenderBox box) {
    final name = box.runtimeType.toString();
    return name.startsWith('Render') ? name.substring(6) : name;
  }
}
