/// Ready-to-copy interceptor for **cloud_firestore** (Firebase Firestore).
///
/// Implements the full [CollectionReference] and [DocumentReference]
/// interfaces — drop-in replacements.
///
/// ## Setup
/// ```dart
/// import 'package:cloud_firestore/cloud_firestore.dart';
///
/// final firestore = FirebaseFirestore.instance;
/// final users = ISpectFirestoreCollection(
///   delegate: firestore.collection('users'),
///   logger: logger,
/// );
///
/// await users.add({'name': 'Alice'});
/// final snapshot = await users.get();
/// final doc = users.doc('alice');
/// await doc.get();
/// ```
library;

// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Wraps a Firestore [CollectionReference] with `ispectify_db` logging.
///
/// Implements [CollectionReference], allowing it to be used as a drop-in
/// replacement. Query-building methods ([where], [orderBy], …) delegate
/// directly — only terminal operations ([get], [add]) are traced.
///
/// [doc] returns a traced [ISpectFirestoreDocument].
final class ISpectFirestoreCollection<T extends Object?>
    implements CollectionReference<T> {
  const ISpectFirestoreCollection({
    required CollectionReference<T> delegate,
    required ISpectLogger logger,
    String source = defaultSource,
  })  : _collection = delegate,
        _logger = logger,
        _source = source;

  final CollectionReference<T> _collection;
  final ISpectLogger _logger;
  final String _source;

  /// Default source identifier.
  static const defaultSource = 'firestore';

  /// The underlying [CollectionReference].
  CollectionReference<T> get delegate => _collection;

  // --- CollectionReference own members --------------------------------------

  @override
  String get id => _collection.id;

  @override
  DocumentReference<Map<String, dynamic>>? get parent => _collection.parent;

  @override
  String get path => _collection.path;

  @override
  ISpectFirestoreDocument<T> doc([String? path]) => ISpectFirestoreDocument(
        delegate: _collection.doc(path),
        logger: _logger,
        source: _source,
      );

  @override
  Future<DocumentReference<T>> add(T data) => _logger.dbTrace(
        source: _source,
        operation: 'add',
        table: _collection.path,
        run: () => _collection.add(data),
        projectResult: (ref) => {'docId': ref.id},
      );

  @override
  CollectionReference<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) =>
      ISpectFirestoreCollection(
        delegate: _collection.withConverter(
          fromFirestore: fromFirestore,
          toFirestore: toFirestore,
        ),
        logger: _logger,
        source: _source,
      );

  // --- Traced Query terminal operations ------------------------------------

  @override
  Future<QuerySnapshot<T>> get([GetOptions? options]) => _logger.dbTrace(
        source: _source,
        operation: 'query',
        table: _collection.path,
        run: () => _collection.get(options),
        projectResult: (snap) => {'docs': snap.size},
      );

  // --- Passthrough Query builders ------------------------------------------

  @override
  FirebaseFirestore get firestore => _collection.firestore;

  @override
  Map<String, dynamic> get parameters => _collection.parameters;

  @override
  Stream<QuerySnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _collection.snapshots(
        includeMetadataChanges: includeMetadataChanges,
        source: source,
      );

  @override
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) =>
      _collection.where(
        field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      );

  @override
  Query<T> orderBy(Object field, {bool descending = false}) =>
      _collection.orderBy(field, descending: descending);

  @override
  Query<T> limit(int limit) => _collection.limit(limit);

  @override
  Query<T> limitToLast(int limit) => _collection.limitToLast(limit);

  @override
  Query<T> startAtDocument(DocumentSnapshot documentSnapshot) =>
      _collection.startAtDocument(documentSnapshot);

  @override
  Query<T> startAt(Iterable<Object?> values) => _collection.startAt(values);

  @override
  Query<T> startAfterDocument(DocumentSnapshot documentSnapshot) =>
      _collection.startAfterDocument(documentSnapshot);

  @override
  Query<T> startAfter(Iterable<Object?> values) =>
      _collection.startAfter(values);

  @override
  Query<T> endAtDocument(DocumentSnapshot documentSnapshot) =>
      _collection.endAtDocument(documentSnapshot);

  @override
  Query<T> endAt(Iterable<Object?> values) => _collection.endAt(values);

  @override
  Query<T> endBeforeDocument(DocumentSnapshot documentSnapshot) =>
      _collection.endBeforeDocument(documentSnapshot);

  @override
  Query<T> endBefore(Iterable<Object?> values) =>
      _collection.endBefore(values);

  @override
  AggregateQuery count() => _collection.count();

  @override
  AggregateQuery aggregate(
    AggregateField aggregateField1, [
    AggregateField? aggregateField2,
    AggregateField? aggregateField3,
    AggregateField? aggregateField4,
    AggregateField? aggregateField5,
    AggregateField? aggregateField6,
    AggregateField? aggregateField7,
    AggregateField? aggregateField8,
    AggregateField? aggregateField9,
    AggregateField? aggregateField10,
    AggregateField? aggregateField11,
    AggregateField? aggregateField12,
    AggregateField? aggregateField13,
    AggregateField? aggregateField14,
    AggregateField? aggregateField15,
    AggregateField? aggregateField16,
    AggregateField? aggregateField17,
    AggregateField? aggregateField18,
    AggregateField? aggregateField19,
    AggregateField? aggregateField20,
    AggregateField? aggregateField21,
    AggregateField? aggregateField22,
    AggregateField? aggregateField23,
    AggregateField? aggregateField24,
    AggregateField? aggregateField25,
    AggregateField? aggregateField26,
    AggregateField? aggregateField27,
    AggregateField? aggregateField28,
    AggregateField? aggregateField29,
    AggregateField? aggregateField30,
  ]) =>
      _collection.aggregate(
        aggregateField1,
        aggregateField2,
        aggregateField3,
        aggregateField4,
        aggregateField5,
        aggregateField6,
        aggregateField7,
        aggregateField8,
        aggregateField9,
        aggregateField10,
        aggregateField11,
        aggregateField12,
        aggregateField13,
        aggregateField14,
        aggregateField15,
        aggregateField16,
        aggregateField17,
        aggregateField18,
        aggregateField19,
        aggregateField20,
        aggregateField21,
        aggregateField22,
        aggregateField23,
        aggregateField24,
        aggregateField25,
        aggregateField26,
        aggregateField27,
        aggregateField28,
        aggregateField29,
        aggregateField30,
      );
}

/// Wraps a Firestore [DocumentReference] with `ispectify_db` logging.
///
/// Implements [DocumentReference], allowing it to be used as a drop-in
/// replacement. CRUD operations ([get], [set], [update], [delete]) are traced.
/// Streams and subcollections delegate directly.
final class ISpectFirestoreDocument<T extends Object?>
    implements DocumentReference<T> {
  const ISpectFirestoreDocument({
    required DocumentReference<T> delegate,
    required ISpectLogger logger,
    String source = defaultSource,
  })  : _doc = delegate,
        _logger = logger,
        _source = source;

  final DocumentReference<T> _doc;
  final ISpectLogger _logger;
  final String _source;

  /// Default source identifier.
  static const defaultSource = 'firestore';

  /// The underlying [DocumentReference].
  DocumentReference<T> get delegate => _doc;

  // --- Traced CRUD ---------------------------------------------------------

  @override
  Future<DocumentSnapshot<T>> get([GetOptions? options]) => _logger.dbTrace(
        source: _source,
        operation: 'get',
        table: _doc.path,
        key: _doc.id,
        run: () => _doc.get(options),
        projectResult: (snap) => {'exists': snap.exists},
      );

  @override
  Future<void> set(T data, [SetOptions? options]) => _logger.dbTrace(
        source: _source,
        operation: 'set',
        table: _doc.path,
        key: _doc.id,
        meta: (options?.merge ?? false) ? {'merge': true} : null,
        run: () => _doc.set(data, options),
      );

  @override
  Future<void> update(Map<Object, Object?> data) => _logger.dbTrace(
        source: _source,
        operation: 'update',
        table: _doc.path,
        key: _doc.id,
        run: () => _doc.update(data),
      );

  @override
  Future<void> delete() => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: _doc.path,
        key: _doc.id,
        run: _doc.delete,
      );

  // --- Passthrough ---------------------------------------------------------

  @override
  FirebaseFirestore get firestore => _doc.firestore;

  @override
  String get id => _doc.id;

  @override
  CollectionReference<T> get parent => _doc.parent;

  @override
  String get path => _doc.path;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _doc.collection(collectionPath);

  @override
  Stream<DocumentSnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      _doc.snapshots(
        includeMetadataChanges: includeMetadataChanges,
        source: source,
      );

  @override
  DocumentReference<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) =>
      ISpectFirestoreDocument(
        delegate: _doc.withConverter(
          fromFirestore: fromFirestore,
          toFirestore: toFirestore,
        ),
        logger: _logger,
        source: _source,
      );
}
