// Generated by Dart Safe Data Class Generator. * Change this header on extension settings *
// ignore_for_file: type=lint
import 'dart:convert';

import 'package:meta/meta.dart';

@immutable
class JiraBoard {
  final int id;
  final String self;
  final String name;
  final String type;
  const JiraBoard({
    this.id = 0,
    this.self = '',
    this.name = '',
    this.type = '',
  });

  JiraBoard copyWith({
    int? id,
    String? self,
    String? name,
    String? type,
  }) {
    return JiraBoard(
      id: id ?? this.id,
      self: self ?? this.self,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'self': self,
      'name': name,
      'type': type,
    };
  }

  factory JiraBoard.fromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');
    return JiraBoard(
      id: cast<num>('id').toInt(),
      self: cast<String>('self'),
      name: cast<String>('name'),
      type: cast<String>('type'),
    );
  }

  String toJson() => json.encode(toMap());

  factory JiraBoard.fromJson(String source) =>
      JiraBoard.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return '''JiraBoard(
      id: $id,
      self: $self,
      name: $name,
      type: $type,
      )''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is JiraBoard &&
        other.id == id &&
        other.self == self &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^ self.hashCode ^ name.hashCode ^ type.hashCode;
  }
}
