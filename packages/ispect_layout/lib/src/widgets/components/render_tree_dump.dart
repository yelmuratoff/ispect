import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:ispect_layout/src/number_format.dart';

/// Plain-text dump of the render subtree rooted at [root], one node per line,
/// indented by depth.
///
/// [RenderObject.toStringDeep] renders inside an `assert` and returns an
/// empty string in profile and release builds. This walker reads only
/// public state (`runtimeType`, size, constraints, parent-data offset), so
/// the output is identical in every build mode short of `--obfuscate`.
String describeRenderTree(RenderObject root, {int decimalPlaces = 1}) {
  final out = StringBuffer();

  void visit(RenderObject node, int depth) {
    out
      ..write('  ' * depth)
      ..writeln(_describeNode(node, decimalPlaces));
    node.visitChildren((child) => visit(child, depth + 1));
  }

  visit(root, 0);
  return out.toString();
}

String _describeNode(RenderObject node, int decimalPlaces) {
  final parts = <String>['${node.runtimeType}#${shortHash(node)}'];
  if (node is RenderBox && node.hasSize) {
    parts.add(
      'size=${formatInspectorSize(node.size, decimalPlaces: decimalPlaces)}',
    );
    parts.add(
      'constraints=${_describeConstraints(node.constraints, decimalPlaces)}',
    );
  }
  if (node.parentData case final BoxParentData data
      when data.offset != Offset.zero) {
    parts.add(
      'offset=${formatInspectorOffset(data.offset, decimalPlaces: decimalPlaces)}',
    );
  }
  return parts.join(' ');
}

String _describeConstraints(BoxConstraints c, int decimalPlaces) {
  String range(double min, double max) {
    final lo = formatInspectorDouble(min, decimalPlaces: decimalPlaces);
    if (min == max) return lo;
    final hi = max == double.infinity
        ? '∞'
        : formatInspectorDouble(max, decimalPlaces: decimalPlaces);
    return '$lo–$hi';
  }

  return 'w${range(c.minWidth, c.maxWidth)} h${range(c.minHeight, c.maxHeight)}';
}
