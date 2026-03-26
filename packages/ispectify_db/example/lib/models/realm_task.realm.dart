// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_task.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class RealmTask extends _RealmTask
    with RealmEntity, RealmObjectBase, RealmObject {
  static var _defaultsSet = false;

  RealmTask(
    ObjectId id,
    String title, {
    bool isComplete = false,
  }) {
    if (!_defaultsSet) {
      _defaultsSet = RealmObjectBase.setDefaults<RealmTask>({
        'isComplete': false,
      });
    }
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'isComplete', isComplete);
  }

  RealmTask._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  bool get isComplete => RealmObjectBase.get<bool>(this, 'isComplete') as bool;
  @override
  set isComplete(bool value) => RealmObjectBase.set(this, 'isComplete', value);

  @override
  Stream<RealmObjectChanges<RealmTask>> get changes =>
      RealmObjectBase.getChanges<RealmTask>(this);

  @override
  Stream<RealmObjectChanges<RealmTask>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<RealmTask>(this, keyPaths);

  @override
  RealmTask freeze() => RealmObjectBase.freezeObject<RealmTask>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'title': title.toEJson(),
      'isComplete': isComplete.toEJson(),
    };
  }

  static EJsonValue _toEJson(RealmTask value) => value.toEJson();
  static RealmTask _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'title': EJsonValue title,
      } =>
        RealmTask(
          fromEJson(id),
          fromEJson(title),
          isComplete: fromEJson(ejson['isComplete'], defaultValue: false),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(RealmTask._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, RealmTask, 'RealmTask', [
      SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
      SchemaProperty('title', RealmPropertyType.string),
      SchemaProperty('isComplete', RealmPropertyType.bool),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
