/// Ready-to-copy interceptor for **cloud_firestore** (Firebase Firestore).
///
/// Provides traced wrappers around [CollectionReference] and
/// [DocumentReference] operations.
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';

/// Wraps a Firestore [CollectionReference] with `ispectify_db` logging.
///
/// Document-level operations are wrapped via [ISpectFirestoreDocument].
final class ISpectFirestoreCollection<T extends Object?> {
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

  /// Collection path.
  String get path => _collection.path;

  /// Returns a traced [ISpectFirestoreDocument] for the given [docPath].
  ISpectFirestoreDocument<T> doc([String? docPath]) => ISpectFirestoreDocument(
        delegate: _collection.doc(docPath),
        logger: _logger,
        source: _source,
      );

  /// Adds a document and logs the generated ID.
  Future<DocumentReference<T>> add(T data) => _logger.dbTrace(
        source: _source,
        operation: 'add',
        table: _collection.path,
        run: () => _collection.add(data),
        projectResult: (ref) => {'docId': ref.id},
      );

  /// Queries all documents in the collection.
  Future<QuerySnapshot<T>> get([GetOptions? options]) => _logger.dbTrace(
        source: _source,
        operation: 'query',
        table: _collection.path,
        run: () => _collection.get(options),
        projectResult: (snap) => {'docs': snap.size},
      );
}

/// Wraps a Firestore [DocumentReference] with `ispectify_db` logging.
final class ISpectFirestoreDocument<T extends Object?> {
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

  /// Document ID.
  String get id => _doc.id;

  /// Document path.
  String get path => _doc.path;

  /// Gets the document snapshot.
  Future<DocumentSnapshot<T>> get([GetOptions? options]) => _logger.dbTrace(
        source: _source,
        operation: 'get',
        table: _doc.path,
        key: _doc.id,
        run: () => _doc.get(options),
        projectResult: (snap) => {'exists': snap.exists},
      );

  /// Sets the document data.
  Future<void> set(T data, [SetOptions? options]) => _logger.dbTrace(
        source: _source,
        operation: 'set',
        table: _doc.path,
        key: _doc.id,
        meta: (options?.merge ?? false) ? {'merge': true} : null,
        run: () => _doc.set(data, options),
      );

  /// Updates specific fields.
  Future<void> update(Map<Object, Object?> data) => _logger.dbTrace(
        source: _source,
        operation: 'update',
        table: _doc.path,
        key: _doc.id,
        run: () => _doc.update(data),
      );

  /// Deletes the document.
  Future<void> delete() => _logger.dbTrace(
        source: _source,
        operation: 'delete',
        table: _doc.path,
        key: _doc.id,
        run: _doc.delete,
      );
}
