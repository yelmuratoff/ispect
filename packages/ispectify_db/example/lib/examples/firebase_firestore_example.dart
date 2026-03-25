/// Example: Firebase Firestore interceptor with fake_cloud_firestore.
///
/// Uses [FakeFirebaseFirestore] for local testing without Firebase setup.
/// In production, replace with `FirebaseFirestore.instance`.
library;

import 'package:cloud_firestore/cloud_firestore.dart' show SetOptions;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/firebase_firestore_interceptor.dart';

Future<void> firestoreExample() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig();

  // Use FakeFirebaseFirestore for local testing.
  // In production: FirebaseFirestore.instance.collection('users')
  final firestore = FakeFirebaseFirestore();
  final users = ISpectFirestoreCollection(
    delegate: firestore.collection('users'),
    logger: logger,
  );

  final posts = ISpectFirestoreCollection(
    delegate: firestore.collection('posts'),
    logger: logger,
  );

  // Add documents
  await users.add({'name': 'Alice', 'role': 'admin'});
  await users.add({'name': 'Bob', 'role': 'user'});

  // Set a specific document
  await users.doc('charlie').set({'name': 'Charlie', 'role': 'user'});

  // Set with merge
  await users.doc('charlie').set({'age': 30}, SetOptions(merge: true));

  // Get a document
  await users.doc('charlie').get();

  // Update a document
  await users.doc('charlie').update({'role': 'admin'});

  // Query the collection
  await users.get();

  // Work with another collection
  await posts.add({'title': 'Hello World', 'authorId': 'charlie'});
  await posts.get();

  // Delete a document
  await users.doc('charlie').delete();
}
