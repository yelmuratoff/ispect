import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/json_utils.dart';
import 'package:ispect/src/core/res/json_color.dart';

class JsonNodeContent extends StatelessWidget {
  const JsonNodeContent({
    required this.keyValue,
    required this.keyColor,
    this.value,
    super.key,
  });

  final String keyValue;
  final Object? value;
  final Color? keyColor;

  @override
  Widget build(BuildContext context) {
    var valueText = '';

    if (value == null) {
      valueText = 'null';
    }

    /// If the value is a List, print its type and cardinality
    /// (example: Array<int>[10])
    if (value is List) {
      final listNode = value! as List;
      valueText = listNode.isEmpty
          ? 'Array[0]'
          : 'Array<${_getTypeName(listNode.first)}>[${listNode.length}]';

      /// If the type is map, output - Object
    } else if (value is Map) {
      valueText = 'Object';
    } else {
      valueText = value is String ? '"$value"' : value.toString();
    }

    return GestureDetector(
      onLongPress: () => _onLongPress(context),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: keyValue,
              style: TextStyle(
                color: keyColor ?? JsonColors.jsonTreeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: valueText,
              style: TextStyle(
                color: _getTypeColor(value),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(Object? content) {
    if (content is int) {
      return JsonColors.intColor;
    } else if (content is String) {
      return JsonColors.stringColor;
    } else if (content is bool) {
      return JsonColors.boolColor;
    } else if (content is double) {
      return JsonColors.doubleColor;
    } else {
      return JsonColors.nullColor;
    }
  }

  String _getTypeName(Object? content) {
    if (content is int) {
      return 'int';
    } else if (content is String) {
      return 'String';
    } else if (content is bool) {
      return 'bool';
    } else if (content is double) {
      return 'double';
    } else if (content is List) {
      return 'List';
    }

    return 'Object';
  }

  void _onLongPress(BuildContext context) {
    copyClipboard(
      context,
      value: value is Map<String, dynamic> ? toJson(value) : value.toString(),
    );
  }
}
