// ignore_for_file: deprecated_member_use, avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/json_viewer/src/models/json_node.dart';

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

  List<InlineSpan> _highlightText(String text, TextStyle style) {
    if (searchQuery.isEmpty) return [TextSpan(text: text, style: style)];
    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    final spans = <InlineSpan>[];
    var start = 0;
    var index = lowerText.indexOf(lowerQuery, start);
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + searchQuery.length),
          style:
              style.copyWith(backgroundColor: highlightColor.withOpacity(0.2)),
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

  Color _getValueColor(Color defaultColor) => switch (type) {
        JsonNodeType.number => JsonColors.numColor,
        JsonNodeType.boolean => JsonColors.boolColor,
        JsonNodeType.object => JsonColors.objectColor,
        JsonNodeType.array => JsonColors.arrayColor,
        JsonNodeType.null_ => Colors.amber,
        _ => defaultColor,
      };

  Color _getValueColorByKey(BuildContext context) {
    final theme = ISpect.read(context).theme;
    return switch (keyName) {
      'key' => theme.getTypeColor(context, key: value.toString()),
      'title' => theme.getTypeColor(context, key: value.toString()),
      'method' => JsonColors.methodColors[value.toString()]!,
      'base-url' => JsonColors.stringColor,
      'url' => JsonColors.stringColor,
      'uri' => JsonColors.stringColor,
      'real-uri' => JsonColors.stringColor,
      'location' => JsonColors.stringColor,
      'path' => JsonColors.stringColor,
      'Authorization' => JsonColors.stringColor,
      'status_code' => JsonColors.getStatusColor(value as int?),
      'exception' => theme.getTypeColor(context, key: 'exception'),
      'error' => theme.getTypeColor(context, key: 'error'),
      'stack-trace' => theme.getTypeColor(context, key: 'error'),
      'log-level' => theme.getColorByLogLevel(context, key: value.toString()),
      'time' => JsonColors.dateTimeColor,
      'date' => JsonColors.dateTimeColor,
      _ => _getValueColor(Theme.of(context).colorScheme.secondary),
    };
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isHighlighted ? highlightColor.withOpacity(0.1) : null,
        ),
        padding: padding,
        child: Row(
          children: [
            _buildExpandButton(),
            const Gap(4),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: _buildTextSpans(context),
                ),
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
