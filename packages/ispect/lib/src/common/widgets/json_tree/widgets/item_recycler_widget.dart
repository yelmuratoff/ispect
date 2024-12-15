import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/src/common/controllers/json_recycler_controller.dart';
import 'package:ispect/src/common/models/elements/json_element.dart';
import 'package:ispect/src/common/models/params/seach_object_param.dart';
import 'package:ispect/src/common/models/value_type.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/core/res/json_color.dart';

class ItemRecyclerWidget extends StatelessWidget {
  const ItemRecyclerWidget({
    required this.callback,
    required this.jsonElement,
    required this.jsonController,
    required this.jsonList,
    super.key,
  });
  final VoidCallback callback;
  final JsonElement jsonElement;
  final JsonRecyclerController jsonController;
  final dynamic jsonList;

  @override
  Widget build(BuildContext context) {
    final isParent = jsonElement.parentRef != null;
    var depthOffset =
        jsonController.horizontalSpaceMultiplier * jsonElement.depth;

    if (!isParent && !jsonController.showStandardJson) {
      depthOffset += jsonController.additionalIndentChildElements;
    }

    return Padding(
      padding: EdgeInsets.only(left: depthOffset),
      child: InkWell(
        onTap: isParent ? callback : null,

        /// If the standard json display mode
        /// mark in color the parent elements
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: jsonController.showStandardJson && isParent
                ? LinearGradient(
                    colors: <Color>[
                      jsonController.standardJsonBackgroundColor,
                      jsonController.standardJsonBackgroundColor
                          .withValues(alpha: 0.1),
                      jsonController.standardJsonBackgroundColor
                          .withValues(alpha: 0.1),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding:
                EdgeInsets.symmetric(vertical: jsonController.verticalOffset),
            child: Row(
              children: [
                /// Show icon only if not standard mode
                /// display json
                if (!jsonController.showStandardJson && isParent)
                  // ignore: use_if_null_to_convert_nulls_to_bools
                  jsonElement.parentRef?.isClosed == true
                      ? jsonController.iconClosed
                      : jsonController.iconOpened,
                Expanded(
                  child: GestureDetector(
                    onLongPress: () => _onLongPress(context),
                    child: jsonElement.valueType != ValueType.hidden
                        ? Text.rich(
                            TextSpan(
                              children: [
                                /// Key value
                                TextSpan(
                                  text: jsonElement.keyValue,
                                  style: TextStyle(
                                    color: jsonController.jsonKeyColor,
                                    fontWeight: jsonController.fontWeight,
                                    fontStyle: jsonController.fontStyle,
                                  ),
                                ),

                                /// Value
                                TextSpan(
                                  text: jsonElement.value,
                                  style: TextStyle(
                                    color: _getColor(jsonElement.valueType),
                                    fontWeight: jsonController.fontWeight,
                                    fontStyle: jsonController.fontStyle,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              Text(
                                jsonElement.keyValue,
                                style: TextStyle(
                                  color: jsonController.jsonKeyColor,
                                  fontWeight: jsonController.fontWeight,
                                  fontStyle: jsonController.fontStyle,
                                ),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  color: JsonColors.hiddenContainerColor,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: const Text(
                                  ISpectConstants.hidden,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(ValueType type) {
    switch (type) {
      case ValueType.int:
        return jsonController.intColor;
      case ValueType.double:
        return jsonController.doubleColor;
      case ValueType.string:
        return jsonController.stringColor;
      case ValueType.nil:
        return jsonController.nullColor;
      case ValueType.bool:
        return jsonController.boolColor;
      case ValueType.object:
        return jsonController.objectColor;
      case ValueType.hidden:
        return jsonController.stringColor;
    }
  }

  /// Copying an item to the buffer
  void _onLongPress(BuildContext context) {
    var copyValue = '';
    final nChildren = jsonElement.parentRef?.nChildren;

    /// If a parent is copied, find and copy its children
    if (nChildren != null) {
      final foundObject = _findObject(
        jsonList,
        SearchObjectParam()..targetIndex = jsonElement.index,
      );

      if (foundObject is Map) {
        copyValue = const JsonEncoder.withIndent('  ').convert(foundObject);
      } else {
        copyValue = foundObject.toString();
      }
    } else {
      copyValue = jsonElement.value.replaceAll('"', '');
    }

    Clipboard.setData(ClipboardData(text: copyValue));
    final snackBar = SnackBar(
      content: Text.rich(
        overflow: TextOverflow.ellipsis,
        maxLines: 4,
        TextSpan(
          children: [
            const TextSpan(text: 'Copy '),
            TextSpan(
              text: '"$copyValue"',
              style: TextStyle(
                color: _getColor(jsonElement.valueType),
              ),
            ),
            const TextSpan(text: ' to clipboard'),
          ],
        ),
      ),
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Recursive search for a parent by index (ordinal number of an element)
  dynamic _findObject(
    Object? someObject,
    SearchObjectParam params,
  ) {
    dynamic result;

    if (params.targetIndex == params.currentIndex) {
      return someObject;
    }

    if (someObject is List) {
      for (final obj in someObject) {
        params.currentIndex++;
        if (obj is List || obj is Map) {
          result = _findObject(obj, params);
          if (result != null) {
            return result;
          }

          /// If standard json view mode is enabled, consider
          /// closing blocks } and ]
          if (jsonController.showStandardJson) {
            params.currentIndex++;
          }
        }
      }
    } else if (someObject is Map) {
      for (final obj in someObject.values) {
        params.currentIndex++;
        if (obj is List || obj is Map) {
          result = _findObject(obj, params);
          if (result != null) {
            return result;
          }

          /// If standard json view mode is enabled, consider
          /// closing blocks } and ]
          if (jsonController.showStandardJson) {
            params.currentIndex++;
          }
        }
      }
    }
  }
}
