import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_logs_viewer/src/core/models/models.dart';
import 'package:web_logs_viewer/src/features/file_viewer/presentation/widgets/file_content_widget.dart';

void main() {
  group('FileContentWidget', () {
    testWidgets('shows the size of the loaded content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileContentWidget(
              content: 'héllo',
              file: const MockFile(content: 'héllo', fileName: 'notes.txt'),
              displayName: 'Text',
              mimeType: 'text/plain',
            ),
          ),
        ),
      );

      expect(find.text('File Size: 6 B'), findsOneWidget);
    });
  });
}
