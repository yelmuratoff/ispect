// ignore: deprecated_member_use
import 'dart:html';

Future<void> downloadFile(String logs) async {
  final blob = Blob(<String>[logs], 'text/plain', 'native');
  final fmtDate = DateTime.now().toString().replaceAll(':', ' ');

  AnchorElement(
    href: Url.createObjectUrlFromBlob(blob),
  )
    ..setAttribute('download', 'app_logs_$fmtDate.txt')
    ..click();
}
