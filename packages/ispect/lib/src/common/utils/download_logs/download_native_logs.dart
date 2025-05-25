import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadFile(
  String logs, {
  String fileName = 'ispect_all_logs',
}) async {
  final dir = await getTemporaryDirectory();
  final dirPath = dir.path;
  final fmtDate = DateTime.now().toString().replaceAll(':', ' ');
  final file =
      await File('$dirPath/${fileName}_$fmtDate.txt').create(recursive: true);
  await file.writeAsString(logs);
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(file.path),
      ],
    ),
  );
}
