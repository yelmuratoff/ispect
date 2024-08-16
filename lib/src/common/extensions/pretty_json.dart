import 'dart:convert';

const decoder = JsonDecoder();
const encoder = JsonEncoder.withIndent('  ');

String prettyJson(Object? input) {
  const encoder = JsonEncoder.withIndent('  ');

  String customToString(Object? value) {
    if (value is Function) {
      return 'Function: ${value.runtimeType}';
    } else if (value.toString().contains('Instance of')) {
      return 'Instance of ${value.runtimeType}';
    } else {
      return value.toString();
    }
  }

  if (input is Map) {
    return encoder.convert(
      input.map((key, value) => MapEntry(key, customToString(value))),
    );
  } else if (input is List) {
    return encoder.convert(input.map(customToString).toList());
  } else if (input.toString().contains('Instance of')) {
    return 'Instance of ${input.runtimeType}';
  } else {
    return encoder.convert(input);
  }
}
