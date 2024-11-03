import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> generateFile(
  String logs, {
  String? name = 'ispect',
}) async {
  final dir = await getTemporaryDirectory();
  final dirPath = dir.path;
  final fmtDate = DateTime.now().toString().replaceAll(':', '-');
  final file =
      await File('$dirPath/$name-$fmtDate.txt').create(recursive: true);
  await file.writeAsString(logs);
  return file;
}
