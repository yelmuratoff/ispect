import 'package:objectbox/objectbox.dart';

@Entity()
class ObjectBoxTask {
  @Id()
  int id = 0;

  late String text;
  bool done = false;
}
