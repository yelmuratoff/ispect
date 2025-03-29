// ignore_for_file: deprecated_member_use, avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';
import 'package:ispect/src/features/json_viewer/src/models/json_node.dart';

/// A single node widget used in the JSON tree view representation.
///
/// This widget displays a JSON key-value pair, optionally with expand/collapse
/// support for nested arrays or objects. It highlights matched search queries,
/// supports customizable styling, and adapts color based on the node's semantic context.
///
/// ### Parameters:
/// - [keyName]: The JSON key to display.
/// - [value]: The corresponding value for the key.
/// - [type]: The data type of the value (used for coloring and formatting).
/// - [isExpanded]: Whether the node is currently expanded.
/// - [onTap]: Callback triggered when the expand icon is tapped.
/// - [expandIcon], [collapseIcon]: Optional override icons for expand/collapse.
/// - [keyStyle], [valueStyle]: Optional text styles for key and value.
/// - [depth]: The nesting level, used externally (not rendered here).
/// - [animationDuration]: Duration of expand animation (not directly used here).
/// - [isHighlighted]: Whether the node should visually indicate a search match.
/// - [highlightColor]: Background color for search highlight.
/// - [searchQuery]: The search text used for partial highlighting.
/// - [padding]: Inner padding around the node row.
class JsonTreeNode extends StatelessWidget {
  const JsonTreeNode({
    required this.keyName,
    required this.value,
    required this.isExpanded,
    required this.onTap,
    required this.type,
    super.key,
    this.keyStyle,
    this.valueStyle,
    this.expandIcon,
    this.collapseIcon,
    this.depth = 0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.isHighlighted = false,
    this.highlightColor = const Color(0xFFFFEB3B),
    this.searchQuery = '',
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final String keyName;
  final dynamic value;
  final bool isExpanded;
  final VoidCallback onTap;
  final TextStyle? keyStyle;
  final TextStyle? valueStyle;
  final Widget? expandIcon;
  final Widget? collapseIcon;
  final int depth;
  final JsonNodeType type;
  final Duration animationDuration;
  final bool isHighlighted;
  final Color highlightColor;
  final String searchQuery;
  final EdgeInsets padding;

  /// Highlights [searchQuery] matches within [text], returning a list of styled [InlineSpan]s.
  List<InlineSpan> _highlightText(String text, TextStyle style) {
    if (searchQuery.isEmpty) return [TextSpan(text: text, style: style)];

    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    final spans = <InlineSpan>[];
    var start = 0;
    var index = lowerText.indexOf(lowerQuery, start);
    final colorHighlight = highlightColor.withOpacity(0.6);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + searchQuery.length),
          style: style.copyWith(
            fontWeight: FontWeight.bold,
            backgroundColor: colorHighlight,
            color: getTextColorOnBackground(colorHighlight),
          ),
        ),
      );
      start = index + searchQuery.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    return spans;
  }

  /// Builds the expand/collapse button or a spacer if not expandable.
  Widget _buildExpandButton() {
    final isExpandable =
        type == JsonNodeType.object || type == JsonNodeType.array;

    return SizedBox(
      width: 20,
      child: isExpandable
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: isExpanded
                  ? collapseIcon ??
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      )
                  : expandIcon ??
                      Icon(
                        Icons.keyboard_arrow_right_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
            )
          : const SizedBox(width: 20),
    );
  }

  /// Wraps highlighted [text] in a [DecoratedBox] with rounded background.
  Widget _buildDecoratedText(String text, TextStyle style, Color bgColor) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text.rich(
            TextSpan(children: _highlightText(text, style)),
          ),
        ),
      );

  /// Constructs styled spans for key-value pair display, with optional decoration.
  List<InlineSpan> _buildTextSpans(BuildContext context) {
    final defaultKeyStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.blue[800],
      letterSpacing: 0.2,
    );
    final keyTextStyle = keyStyle ?? defaultKeyStyle;
    final valueColor = _getValueColorByKey(context);
    final defaultValueStyle = TextStyle(color: valueColor);
    final valueTextStyle =
        valueStyle?.copyWith(color: valueColor) ?? defaultValueStyle;

    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.top,
        child: _buildDecoratedText(
          keyName,
          keyTextStyle,
          keyTextStyle.color?.withOpacity(0.2) ?? Colors.grey[200]!,
        ),
      ),
      const TextSpan(
        text: ': ',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400),
      ),
      if (type == JsonNodeType.object || type == JsonNodeType.array)
        TextSpan(children: _highlightText(_displayValue(), valueTextStyle))
      else
        WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: _buildDecoratedText(
            _displayValue(),
            valueTextStyle,
            valueColor.withOpacity(0.2),
          ),
        ),
    ];
  }

  /// Converts the node value into a human-readable display string.
  String _displayValue() {
    if (type == JsonNodeType.object || type == JsonNodeType.array) {
      final isObject = type == JsonNodeType.object;
      final open = isObject ? '{' : '[';
      final close = isObject ? '}' : ']';
      return isExpanded
          ? (value.length == 0 ? '$open$close' : '$open...$close')
          : '$open${value.length}$close';
    } else if (type == JsonNodeType.string) {
      return '"$value"';
    }
    return value.toString();
  }

  /// Returns a default color based on the [JsonNodeType].
  Color _getValueColor(Color defaultColor) => switch (type) {
        JsonNodeType.number => JsonColors.numColor,
        JsonNodeType.boolean => JsonColors.boolColor,
        JsonNodeType.object => JsonColors.objectColor,
        JsonNodeType.array => JsonColors.arrayColor,
        JsonNodeType.null_ => Colors.amber,
        _ => defaultColor,
      };

  /// Resolves the display color of the value based on the [keyName].
  Color _getValueColorByKey(BuildContext context) {
    final theme = ISpect.read(context).theme;
    return switch (keyName) {
      'key' => theme.getTypeColor(context, key: value.toString()),
      'title' => theme.getTypeColor(context, key: value.toString()),
      'method' => JsonColors.methodColors[value.toString()]!,
      'base-url' ||
      'url' ||
      'uri' ||
      'real-uri' ||
      'location' ||
      'path' ||
      'Authorization' =>
        JsonColors.stringColor,
      'status_code' => JsonColors.getStatusColor(value as int?),
      'exception' => theme.getTypeColor(context, key: 'exception'),
      'error' => theme.getTypeColor(context, key: 'error'),
      'stack-trace' => theme.getTypeColor(context, key: 'error'),
      'log-level' => theme.getColorByLogLevel(context, key: value.toString()),
      'time' || 'date' => JsonColors.dateTimeColor,
      _ => _getValueColor(Theme.of(context).colorScheme.secondary),
    };
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isHighlighted ? highlightColor.withOpacity(0.2) : null,
        ),
        padding: padding,
        child: Row(
          children: [
            _buildExpandButton(),
            const Gap(4),
            Expanded(
              child: Text.rich(
                TextSpan(children: _buildTextSpans(context)),
                style: const TextStyle(
                  height: 1.5,
                  fontSize: 14,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
          ],
        ),
      );
}
