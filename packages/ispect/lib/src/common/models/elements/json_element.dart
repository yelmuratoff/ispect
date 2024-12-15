import 'package:ispect/src/common/models/elements/json_parent_element.dart';
import 'package:ispect/src/common/models/value_type.dart';

/// The element that makes up the json widget
class JsonElement {
  JsonParentElement? parentRef;
  String keyValue = '';
  String value = '';
  int shiftIndex = 0;
  int index = 0;
  int depth = 0;
  ValueType valueType = ValueType.object;
}
