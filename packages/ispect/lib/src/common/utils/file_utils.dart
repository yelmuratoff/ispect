import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final class FileUtils {
  const FileUtils._();

  static Future<XFile> writeImageToStorage(Uint8List feedbackScreenshot) async {
    final output = await getTemporaryDirectory();
    final screenshotFilePath =
        '${output.path}/feedback${feedbackScreenshot.hashCode}.png';
    final screenshotFile = File(screenshotFilePath);
    await screenshotFile.writeAsBytes(feedbackScreenshot);
    return XFile(screenshotFilePath, bytes: feedbackScreenshot);
  }
}
