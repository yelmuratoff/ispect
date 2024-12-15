import 'dart:convert';

const encoder = JsonEncoder.withIndent('  ');

String prettyJson(Object? input) {
  Object? toEncodable(Object? value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key, toEncodable(value)));
    } else if (value is List) {
      return value.map(toEncodable).toList();
    } else if (value != null) {
      try {
        // Check if the object has a toJson method

        // ignore: avoid_dynamic_calls
        final json = (value as dynamic).toJson();
        return toEncodable(json);
      } catch (_) {
        // Fallback if toJson is not present or fails
        return value.toString();
      }
    } else {
      return value;
    }
  }

  try {
    return encoder.convert(toEncodable(input));
  } catch (e) {
    return 'Error encoding JSON: $e';
  }
}
