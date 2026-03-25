import 'package:isar_community/isar.dart';

part 'isar_post.g.dart';

@collection
class IsarPost {
  Id id = Isar.autoIncrement;

  String? title;

  String? content;

  int? authorId;
}
