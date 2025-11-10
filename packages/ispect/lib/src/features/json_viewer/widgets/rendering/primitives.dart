import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/theme.dart';
import 'package:ispect/src/features/json_viewer/widgets/json_attribute.dart';
import 'package:ispect/src/features/json_viewer/widgets/paints/dot_painter.dart';

class CopyButton extends StatelessWidget {
  const CopyButton({
    required this.node,
    required this.theme,
    super.key,
  });

  final NodeViewModelState node;
  final JsonExplorerTheme theme;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        onTap: () {
          copyClipboard(
            context,
            value: '${node.key}: ${JsonTruncatorService.pretty(node.rawValue)}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            Icons.copy_rounded,
            size: 14,
            color: theme.rootKeyTextStyle.color,
          ),
        ),
      );
}

class IndentationWidget extends StatelessWidget {
  const IndentationWidget({
    required this.depth,
    required this.indentationPadding,
    required this.color,
    super.key,
  });

  final int depth;
  final double indentationPadding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final indentation = depth > 0
        ? ((depth + 1) * indentationPadding).clamp(0, 100)
        : indentationPadding;
    return Padding(
      padding: const EdgeInsets.only(right: 4, left: 4),
      child: CustomPaint(
        painter: DotPainter(
          count: (indentation / 5).clamp(0, double.infinity),
          color: color,
        ),
        size: Size(
          indentation.toDouble(),
          20,
        ),
      ),
    );
  }
}

class ArraySuffixWidget extends StatelessWidget {
  const ArraySuffixWidget({
    required this.length,
    required this.style,
    super.key,
  });
  final int length;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Flexible(
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '[$length]',
            style: style.copyWith(
              color: JsonColors.arrayColor,
            ),
          ),
        ),
      );
}

class MapSuffixWidget extends StatelessWidget {
  const MapSuffixWidget({required this.length, required this.style, super.key});
  final int length;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Flexible(
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '{$length}',
            style: style.copyWith(
              color: JsonColors.objectColor,
            ),
          ),
        ),
      );
}

/// Text separator widget showing colon between key and value
class KeySeparatorText extends StatefulWidget {
  const KeySeparatorText({super.key});

  @override
  State<KeySeparatorText> createState() => _KeySeparatorTextState();
}

class _KeySeparatorTextState extends State<KeySeparatorText> {
  JsonExplorerTheme? _cachedTheme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedTheme =
        context.findAncestorWidgetOfExactType<JsonAttribute>()?.theme;
  }

  @override
  Widget build(BuildContext context) =>
      Text(':', style: _cachedTheme?.rootKeyTextStyle);
}

/// Toggle button for expanding/collapsing nodes
class ToggleButton extends StatefulWidget {
  const ToggleButton({super.key});

  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  JsonAttribute? _cachedJsonAttribute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedJsonAttribute =
        context.findAncestorWidgetOfExactType<JsonAttribute>();
  }

  @override
  Widget build(BuildContext context) {
    final jsonAttribute = _cachedJsonAttribute!;
    final node = jsonAttribute.node;
    final toggle = jsonAttribute.collapsableToggleBuilder;

    return ListenableBuilder(
      listenable: node,
      builder: (context, child) =>
          toggle?.call(context, node) ??
          (AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Icon(
              node.isCollapsed
                  ? Icons.arrow_right_rounded
                  : Icons.arrow_drop_down_rounded,
              key: ValueKey(node.isCollapsed),
              color: jsonAttribute.theme.rootKeyTextStyle.color,
            ),
          )),
    );
  }
}
