import 'package:flutter/material.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
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

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isHighlighted ? highlightColor.withValues(alpha: 0.3) : null,
        ),
        padding: padding,
        child: Row(
          children: [
            InkWell(
              onTap: (type == JsonNodeType.object || type == JsonNodeType.array)
                  ? onTap
                  : null,
              borderRadius: const BorderRadius.all(
                Radius.circular(4),
              ),
              child: _buildExpandButton(),
            ),
            const Gap(4),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: _buildTextSpans(),
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

  Widget _buildExpandButton() {
    if (type == JsonNodeType.object || type == JsonNodeType.array) {
      return SizedBox(
        width: 20,
        child: isExpanded
            ? (collapseIcon ??
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.grey[600],
                ))
            : (expandIcon ??
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: Colors.grey[600],
                )),
      );
    }
    return const SizedBox(width: 20);
  }

  List<InlineSpan> _buildTextSpans() {
    final defaultKeyStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.blue[800],
      letterSpacing: 0.2,
    );

    final defaultValueStyle = TextStyle(
      color: _getValueColor(),
      letterSpacing: 0.2,
    );

    if (searchQuery.isEmpty) {
      return [
        WidgetSpan(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  keyStyle?.color?.withValues(alpha: 0.2) ?? Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                keyName,
                style: keyStyle ?? defaultKeyStyle,
              ),
            ),
          ),
        ),
        TextSpan(
          text: ': ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        if (type == JsonNodeType.object || type == JsonNodeType.array)
          TextSpan(
            text: _getDisplayValue(),
            style: defaultValueStyle,
          )
        else
          WidgetSpan(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: valueStyle?.color?.withValues(alpha: 0.2) ??
                    Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  _getDisplayValue(),
                  style: valueStyle ?? defaultValueStyle,
                ),
              ),
            ),
          ),
      ];
    }

    return _buildHighlightedText(
      '$keyName: ${_getDisplayValue()}',
      searchQuery,
      keyStyle ?? defaultKeyStyle,
      valueStyle ?? defaultValueStyle,
    );
  }

  List<TextSpan> _buildHighlightedText(
    String text,
    String query,
    TextStyle keyStyle,
    TextStyle valueStyle,
  ) {
    final spans = <TextSpan>[];
    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    var start = 0;

    while (true) {
      final index = lowercaseText.indexOf(lowercaseQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(
            TextSpan(
              text: text.substring(start),
              style: start < keyName.length ? keyStyle : valueStyle,
            ),
          );
        }
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: start < keyName.length ? keyStyle : valueStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            backgroundColor: highlightColor,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return spans;
  }

  String _getDisplayValue() {
    switch (type) {
      case JsonNodeType.object:
        return isExpanded ? '' : '{...}';
      case JsonNodeType.array:
        return isExpanded ? '' : '[...]';
      case JsonNodeType.string:
        return '"$value"';
      default:
        return value.toString();
    }
  }

  Color _getValueColor() {
    switch (type) {
      case JsonNodeType.string:
        return Colors.green[800]!;
      case JsonNodeType.number:
        return Colors.purple[800]!;
      case JsonNodeType.boolean:
        return Colors.orange[800]!;
      case JsonNodeType.null_:
        return Colors.grey[600]!;
      default:
        return Colors.grey[800]!;
    }
  }
}
