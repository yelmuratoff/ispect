// ignore_for_file: avoid_public_members_in_states, duplicate_ignore
import 'package:flutter/cupertino.dart';
import 'package:ispect/src/common/controllers/json_recycler_controller.dart';
import 'package:ispect/src/common/models/current_parent_index.dart';
import 'package:ispect/src/common/models/elements/json_element.dart';
import 'package:ispect/src/common/models/elements/json_parent_element.dart';
import 'package:ispect/src/common/models/params/preparing_param.dart';
import 'package:ispect/src/common/models/value_type.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

abstract class IRecycler {
  late final JsonRecyclerController jsonController;
  late final dynamic json;
}

abstract class BaseRecyclerPageState<T extends StatefulWidget> extends State<T>
    implements IRecycler {
  final _jsonList = <JsonElement>[];
  int _jsonListLength = 0;
  bool _isExpanded = false;
  CurrentParentIndex? _currentParentIndex;

  bool get rootExpanded => false;

  int get jsonListLength => _jsonListLength;

  List<JsonElement> get jsonList => _jsonList;

  @override
  void initState() {
    super.initState();
    _jsonList.addAll(
      _creatingListElements(
        json,
        PreparingParam(),
      ),
    );
    _jsonListLength = _jsonList.length;
    _isExpanded = jsonController.isExpanded;

    if (!_isExpanded) {
      _closeJson();
    }

    if (rootExpanded) {
      _currentParentIndex = CurrentParentIndex(0, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    /// If the parent was clicked, calculate the offset
    final currentPressedIndex = _currentParentIndex;
    if (currentPressedIndex != null) {
      _changeListState(
        currentPressedIndex.index,
        currentPressedIndex.originalIndex,
      );

      _currentParentIndex = null;
    }

    if (_isExpanded != jsonController.isExpanded) {
      if (jsonController.isExpanded) {
        _openJson();
      } else {
        _closeJson();
      }

      _isExpanded = jsonController.isExpanded;
    }

    return bodyWidget(context);
  }

  // ignore: avoid_returning_widgets, avoid_public_members_in_states
  Widget bodyWidget(BuildContext context);

  /// Creating a list of elements from the received object
  /// Recursion going through all elements of the json
  List<JsonElement> _creatingListElements(
    Object? someObject,
    PreparingParam params,
  ) {
    /// Если List
    if (someObject is List) {
      final jsonElem = <JsonElement>[];
      final parentIndex = params.index;
      var parentKey = '';
      var parentValue = '';

      /// Display the parent element
      if (jsonController.showStandardJson) {
        parentKey = '${params.keyValue}[';
      } else {
        parentValue = 'Array<Object>[${someObject.length}]';
        parentKey = params.keyValue;
      }

      final children = <JsonElement>[];
      for (var i = 0; i < someObject.length; i++) {
        final obj = someObject[i];
        if (obj is List || obj is Map) {
          params.index++;
          params.depth++;

          /// Passing the display to the child parent
          if (obj is Map) {
            if (jsonController.showStandardJson) {
              params.keyValue = '';
            } else {
              params.keyValue = '[$i]: ';
            }
          }

          children.addAll(_creatingListElements(obj, params));
          params.depth--;
        } else {
          params.index++;

          final newNode = JsonElement()
            ..value = _valueToString(obj)
            ..valueType = _getType(obj)
            ..shiftIndex = params.index
            ..index = params.index
            ..depth = params.depth + 1;
          children.add(newNode);
        }
      }

      /// Creating a parent
      final parentElement = JsonParentElement()
        ..isClosed = false
        ..nChildren =
            children.length + (jsonController.showStandardJson ? 2 : 1);

      final parentNode = JsonElement()
        ..parentRef = parentElement
        ..keyValue = parentKey
        ..value = parentValue
        ..valueType = ValueType.object
        ..shiftIndex = parentIndex
        ..index = parentIndex
        ..depth = params.depth;

      /// Saving the parent and then the child elements
      jsonElem
        ..add(parentNode)
        ..addAll(children);

      /// Shows the closing of the List block
      if (jsonController.showStandardJson) {
        params.index++;
        final newNodeEnd = JsonElement()
          ..keyValue = ']'
          ..value = ''
          ..valueType = ValueType.object
          ..shiftIndex = params.index
          ..index = params.index
          ..depth = params.depth;

        jsonElem.add(newNodeEnd);
      }

      return jsonElem;

      /// if Map
    } else if (someObject is Map) {
      final jsonElem = <JsonElement>[];
      final parentIndex = params.index;
      var parentKey = '';
      var parentValue = '';

      /// Display the parent element
      if (jsonController.showStandardJson) {
        parentKey = '${params.keyValue}{';
      } else {
        parentValue = 'Object';
        parentKey = params.keyValue;
      }

      final children = <JsonElement>[];
      for (final obj in someObject.entries) {
        final value = obj.value;

        if (value is List || value is Map) {
          params.index++;
          params.depth++;
          params.keyValue = '${obj.key}: ';

          children.addAll(_creatingListElements(value, params));
          params.depth--;
        } else {
          params.index++;

          final newNode = JsonElement()
            ..keyValue = '${obj.key}: '
            ..value = _valueToString(value)
            ..valueType = _getType(value)
            ..shiftIndex = params.index
            ..index = params.index
            ..depth = params.depth + 1;

          children.add(newNode);
        }
      }

      /// Creating a parent
      final parentElement = JsonParentElement()
        ..isClosed = false
        ..nChildren =
            children.length + (jsonController.showStandardJson ? 2 : 1);

      final parentNode = JsonElement()
        ..parentRef = parentElement
        ..keyValue = parentKey
        ..value = parentValue
        ..valueType = ValueType.object
        ..shiftIndex = parentIndex
        ..index = parentIndex
        ..depth = params.depth;

      /// Saving the parent and then the child elements
      jsonElem
        ..add(parentNode)
        ..addAll(children);

      /// Shows the closing of the Map block
      if (jsonController.showStandardJson) {
        params.index++;
        final newNodeEnd = JsonElement()
          ..keyValue = '}'
          ..value = ''
          ..valueType = ValueType.object
          ..shiftIndex = params.index
          ..index = params.index
          ..depth = params.depth;

        jsonElem.add(newNodeEnd);
      }

      return jsonElem;

      /// If other types
    } else {
      final newNode = JsonElement()
        ..value = _valueToString(someObject)
        ..valueType = _getType(someObject)
        ..shiftIndex = params.index
        ..index = params.index;

      return [newNode];
    }
  }

  /// Return string value
  /// If value is already a string, wrap it in double quotes
  String _valueToString(Object? value) =>
      value is String ? '"$value"' : value.toString();

  /// Calculating element shifts when the parent is open/closed
  void _changeListState(int index, int orig) {
    if (_jsonList[index].parentRef != null) {
      _jsonList[index].parentRef!.isClosed =
          !_jsonList[index].parentRef!.isClosed;

      final isClosedSign = _jsonList[index].parentRef!.isClosed ? 1 : -1;

      /// -1 remove influence on the parent
      var shiftValue = _jsonList[index].parentRef!.nChildren - 1;
      var cutLengthArrayValue = shiftValue * -isClosedSign;

      var sumClosedChildren = 0;
      if (orig + 1 < _jsonList.length) {
        /// When closing, counting the child closed elements so as /// not to reduce the size of the array twice.
        final lastIndex = index + shiftValue;
        var skipChildrenLastIndex = -1;

        for (var i = index + 1; i < lastIndex; i++) {
          /// If the parent was closed, skip checking all children
          if (i < skipChildrenLastIndex) {
            continue;
          }

          // ignore: use_if_null_to_convert_nulls_to_bools
          if (_jsonList[i].parentRef?.isClosed == true) {
            final nChildren = _jsonList[i].parentRef?.nChildren;
            if (nChildren != null) {
              sumClosedChildren += nChildren - 1;

              /// If the child parent is closed, count as 1 item
              shiftValue -= nChildren - 1;

              skipChildrenLastIndex = i + nChildren;
            }
          }
        }

        cutLengthArrayValue += sumClosedChildren * isClosedSign;

        /// Changing the size of the array
        _jsonListLength += cutLengthArrayValue;

        for (var i = orig + 1; i < _jsonListLength; i++) {
          /// Closing elements
          if (isClosedSign > 0) {
            final indexWithShift = i + shiftValue;

            /// Copying an existing offset
            if (indexWithShift < _jsonList.length) {
              _jsonList[i].shiftIndex = _jsonList[indexWithShift].shiftIndex;
            }

            /// Opening Elements
          } else {
            /// Offset all values by the number of child elements
            for (var j = _jsonListLength - 1; j >= orig + shiftValue; j--) {
              _jsonList[j].shiftIndex = _jsonList[j - shiftValue].shiftIndex;
            }

            var shiftIndex = index + 1;
            var step = 0;

            /// Insert missing values
            for (var j = 0; j < shiftValue; j++) {
              /// Calculation of displacement
              final targetIndex = shiftIndex + step;
              step++;

              /// Goes through the elements one by one and assigns a new offset
              _jsonList[i + j].shiftIndex = targetIndex;

              /// If a closed parent was found, set a new offset
              // ignore: use_if_null_to_convert_nulls_to_bools
              if (_jsonList[targetIndex].parentRef?.isClosed == true) {
                final nChildren = _jsonList[targetIndex].parentRef?.nChildren;
                if (nChildren != null) {
                  shiftIndex = targetIndex + nChildren;
                  step = 0;
                }
              }
            }
            break;
          }
        }

        /// Reset history of closed children (close)
        if (!jsonController.saveClosedHistory && isClosedSign > 0) {
          /// End of Map/List block
          final endBlock = _jsonList[index].parentRef!.nChildren - 1;
          for (var i = orig + 1; i < endBlock; i++) {
            _jsonList[i].parentRef?.isClosed = true;
          }
        }
      }
    }
  }

  /// Reset all shifts (open all parents)
  void _openJson() {
    for (var i = 0; i < _jsonList.length; i++) {
      _jsonList[i].shiftIndex = i;
      _jsonList[i].parentRef?.isClosed = false;
    }

    setState(() {
      _jsonListLength = _jsonList.length;
    });
  }

  /// Closing all parents
  void _closeJson() {
    for (var i = 0; i < _jsonList.length; i++) {
      _jsonList[i].parentRef?.isClosed = true;
    }

    setState(() {
      _jsonListLength = 1;
    });
  }

  /// Set value type
  ValueType _getType(Object? value) {
    if (value is int) {
      return ValueType.int;
    } else if (value is double) {
      return ValueType.double;
    } else if (value is String) {
      if (value == ISpectConstants.hidden) {
        return ValueType.hidden;
      } else {
        return ValueType.string;
      }
    } else if (value == null) {
      return ValueType.nil;
    } else if (value is bool) {
      return ValueType.bool;
    }

    return ValueType.object;
  }

  // ignore: avoid_public_members_in_states
  void rememberIndexOfParent(int indexWithShift, int index) {
    /// Remember the indexes of the parent you clicked on
    if (_currentParentIndex == null) {
      setState(() {
        _currentParentIndex = CurrentParentIndex(indexWithShift, index);
      });
    }
  }
}
