import 'dart:convert';

String toJson(Object? data) {
  const je = JsonEncoder.withIndent('  ');
  final json = je.convert(data);

  return json;
}
