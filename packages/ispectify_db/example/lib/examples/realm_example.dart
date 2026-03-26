import 'package:ispectify/ispectify.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_db_example/interceptors/realm_interceptor.dart';
import 'package:ispectify_db_example/models/realm_task.dart';
import 'package:realm/realm.dart';

Future<void> realmExample() async {
  final logger = ISpectLogger();
  ISpectDbCore.config = ISpectDbConfig();

  final config = Configuration.inMemory([RealmTask.schema]);
  final realm = Realm(config);
  final traced = ISpectRealm(delegate: realm, logger: logger);

  try {
    // --- Writes inside a transaction ----------------------------------------
    traced.write(() {
      traced.add(RealmTask(ObjectId(), 'Buy milk'));
      traced.add(RealmTask(ObjectId(), 'Write tests', isComplete: true));
    });

    // --- Bulk add -----------------------------------------------------------
    traced.write(() {
      traced.addAll([
        RealmTask(ObjectId(), 'Review PR'),
        RealmTask(ObjectId(), 'Deploy'),
      ]);
    });

    // --- Reads --------------------------------------------------------------
    final all = traced.all<RealmTask>();
    logger.info('All tasks: ${all.length}');

    final incomplete = traced.query<RealmTask>('isComplete == \$0', [false]);
    logger.info('Incomplete tasks: ${incomplete.length}');

    final first = all.first;
    final found = traced.find<RealmTask>(first.id);
    logger.info('Found: ${found?.title}');

    // --- Update inside transaction ------------------------------------------
    traced.write(() {
      final task = traced.find<RealmTask>(first.id);
      if (task != null) {
        task.isComplete = true;
      }
    });

    // --- Delete -------------------------------------------------------------
    traced.write(() {
      final toDelete = traced.all<RealmTask>().first;
      traced.delete(toDelete);
    });

    // --- Async write --------------------------------------------------------
    await traced.writeAsync(() {
      traced.delegate.deleteAll<RealmTask>();
    });
  } finally {
    realm.close();
  }
}
