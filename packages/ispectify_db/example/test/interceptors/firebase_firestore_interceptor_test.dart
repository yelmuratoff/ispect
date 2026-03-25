import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/firebase_firestore_interceptor.dart';
import 'package:test/test.dart';

void main() {
  late ISpectLogger logger;
  late FakeFirebaseFirestore fakeFirestore;
  late ISpectFirestoreCollection<Map<String, dynamic>> traced;

  setUp(() {
    logger = ISpectLogger();
    ISpectDbCore.config = ISpectDbConfig();
    fakeFirestore = FakeFirebaseFirestore();
    traced = ISpectFirestoreCollection(
      delegate: fakeFirestore.collection('users'),
      logger: logger,
    );
  });

  tearDown(() => ISpectDbCore.config = ISpectDbConfig());

  Map<String, Object?> lastAdditional() =>
      logger.history.last.additionalData ?? {};

  group('collection.add', () {
    test('adds document and logs insert', () async {
      final ref = await traced.add({'name': 'Alice'});

      expect(ref.id, isNotEmpty);
      expect(lastAdditional()['source'], 'firestore');
      expect(lastAdditional()['operation'], 'insert');
      expect(lastAdditional()['table'], 'users');
    });
  });

  group('collection.get', () {
    test('queries all docs and logs count', () async {
      await fakeFirestore
          .collection('users')
          .add({'name': 'Alice'});
      await fakeFirestore
          .collection('users')
          .add({'name': 'Bob'});

      final snap = await traced.get();

      expect(snap.size, 2);
      expect(lastAdditional()['operation'], 'query');
      expect(logger.history.last.key, 'db-query');
    });
  });

  group('collection.doc', () {
    test('returns traced document reference', () {
      final doc = traced.doc('alice');

      expect(doc, isA<ISpectFirestoreDocument<Map<String, dynamic>>>());
      expect(doc.id, 'alice');
    });
  });

  group('document.get', () {
    test('reads document and logs exists', () async {
      await fakeFirestore
          .collection('users')
          .doc('alice')
          .set({'name': 'Alice'});

      final doc = traced.doc('alice');
      final snap = await doc.get();

      expect(snap.exists, isTrue);
      expect(snap.data(), containsPair('name', 'Alice'));

      expect(lastAdditional()['source'], 'firestore');
      expect(lastAdditional()['operation'], 'get');
      expect(lastAdditional()['key'], 'alice');
    });

    test('logs non-existent document', () async {
      final snap = await traced.doc('missing').get();

      expect(snap.exists, isFalse);
    });
  });

  group('document.set', () {
    test('creates document and logs', () async {
      await traced.doc('bob').set({'name': 'Bob'});

      final snap = await fakeFirestore
          .collection('users')
          .doc('bob')
          .get();
      expect(snap.data(), containsPair('name', 'Bob'));

      expect(lastAdditional()['operation'], 'write');
      expect(lastAdditional()['key'], 'bob');
    });
  });

  group('document.update', () {
    test('updates fields and logs', () async {
      await fakeFirestore
          .collection('users')
          .doc('alice')
          .set({'name': 'Alice', 'role': 'user'});

      await traced.doc('alice').update({'role': 'admin'});

      final snap = await fakeFirestore
          .collection('users')
          .doc('alice')
          .get();
      expect(snap.data(), containsPair('role', 'admin'));

      expect(lastAdditional()['operation'], 'update');
    });
  });

  group('document.delete', () {
    test('deletes document and logs', () async {
      await fakeFirestore
          .collection('users')
          .doc('alice')
          .set({'name': 'Alice'});

      await traced.doc('alice').delete();

      final snap = await fakeFirestore
          .collection('users')
          .doc('alice')
          .get();
      expect(snap.exists, isFalse);

      expect(lastAdditional()['operation'], 'delete');
    });
  });

  group('path passthrough', () {
    test('collection path', () {
      expect(traced.path, 'users');
    });

    test('document path and id', () {
      final doc = traced.doc('alice');
      expect(doc.path, 'users/alice');
      expect(doc.id, 'alice');
    });
  });

  group('custom source', () {
    test('uses provided source', () async {
      final custom = ISpectFirestoreCollection(
        delegate: fakeFirestore.collection('test'),
        logger: logger,
        source: 'firebase-emulator',
      );
      await custom.add({'test': true});

      expect(lastAdditional()['source'], 'firebase-emulator');
    });
  });
}
