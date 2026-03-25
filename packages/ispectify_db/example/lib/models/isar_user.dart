import 'package:isar_community/isar.dart';

part 'isar_user.g.dart';

@Collection()
class IsarUser {
  Id id = Isar.autoIncrement;
  late String name;
  String? email;
}
