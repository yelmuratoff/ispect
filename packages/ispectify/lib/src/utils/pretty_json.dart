import 'dart:convert';

/// JSON encoder with indentation for pretty-printing.
const JsonEncoder encoder = JsonEncoder.withIndent('  ');

/// Converts an object to a pretty-printed JSON string.
///
/// - If the object has a `toJson()` method, it will be used for conversion.
/// - Handles lists and maps recursively.
/// - Fallbacks to `toString()` for unsupported objects.
/// - Returns an error message if encoding fails.
///
/// ### Example:
/// ```dart
/// final data = {'name': 'John', 'age': 30};
/// print(prettyJson(data));
/// ```
///
/// **Output:**
/// ```json
/// {
///   "name": "John",
///   "age": 30
/// }
/// ```
// String prettyJson(Object? input) {
//   /// Recursively converts an object to an encodable JSON format.
//   Object? toEncodable(Object? value) {
//     if (value == null) return null;

//     if (value is Map) {
//       return value.map((key, val) => MapEntry(key, toEncodable(val)));
//     } else if (value is List) {
//       return value.map(toEncodable).toList();
//     } else {
//       try {
//         // If the object has a toJson method, use it
//         final json = (value as dynamic).toJson();
//         return json is Map || json is List ? toEncodable(json) : json;
//       } catch (_) {
//         // If conversion fails, return the string representation
//         return value.toString();
//       }
//     }
//   }

//   try {
//     return encoder.convert(toEncodable(input));
//   } catch (e) {
//     return 'Error encoding JSON: $e';
//   }
// }
