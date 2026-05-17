import 'package:realm/realm.dart';

part 'realm_task.realm.dart';

@RealmModel()
class _RealmTask {
  @PrimaryKey()
  late ObjectId id;

  late String title;
  bool isComplete = false;
}
