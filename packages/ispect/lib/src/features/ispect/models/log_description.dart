// Generated by Dart Safe Data Class Generator. * Change this header on extension settings *
// ignore_for_file: type=lint
import 'dart:convert';

import 'package:meta/meta.dart';

@immutable
final class LogDescription {
  final String key;
  final String? description;
  final bool isDisabled;
  const LogDescription({
    required this.key,
    this.description,
    this.isDisabled = false,
  });

  LogDescription copyWith({
    String? key,
    String? description,
    bool? isDisabled,
  }) {
    return LogDescription(
      key: key ?? this.key,
      description: description ?? this.description,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'description': description,
      'is_disabled': isDisabled,
    };
  }

  factory LogDescription.fromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');
    return LogDescription(
      key: cast<String>('key'),
      description: cast<String>('description'),
      isDisabled: cast<bool>('is_disabled'),
    );
  }

  String toJson() => json.encode(toMap());

  factory LogDescription.fromJson(String source) =>
      LogDescription.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'LogDescription(key: $key, description: $description, isDisabled: $isDisabled)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LogDescription &&
        other.key == key &&
        other.description == description &&
        other.isDisabled == isDisabled;
  }

  @override
  int get hashCode => key.hashCode ^ description.hashCode ^ isDisabled.hashCode;
}
