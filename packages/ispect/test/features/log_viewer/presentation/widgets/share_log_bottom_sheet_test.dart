import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/share_log_bottom_sheet.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  group('ISpectShareLogBottomSheet.buildContent', () {
    final data = <String, dynamic>{
      'id': '01KVDNQHAXXDD3V4967PV198FP',
      'key': 'info',
      'time': '2026-06-18T20:31:25.149609',
      'log-level': '3',
      'message': '[badge] NotificationCountCubit.get: server count=18',
    };

    const metadata = ISpectMetadata(
      appName: 'ISpect Quick Start',
      appVersion: '1.0.0',
      buildNumber: '1',
      environment: 'dev',
    );

    test('merges environment metadata into the exported JSON record', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
        metadata: metadata,
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final exportedMeta = decoded['metadata'] as Map<String, dynamic>;
      expect(exportedMeta['appName'], equals('ISpect Quick Start'));
      expect(exportedMeta['appVersion'], equals('1.0.0'));
      expect(exportedMeta['buildNumber'], equals('1'));
      expect(exportedMeta['environment'], equals('dev'));
      expect(decoded['id'], equals('01KVDNQHAXXDD3V4967PV198FP'));
      expect(
        decoded['message'],
        equals('[badge] NotificationCountCubit.get: server count=18'),
      );
    });

    test('omits the metadata block when no metadata is supplied', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded.containsKey('metadata'), isFalse);
    });

    test('omits the metadata block when metadata has no fields set', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
        metadata: const ISpectMetadata(),
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded.containsKey('metadata'), isFalse);
    });

    test('copy action exports the truncated record with metadata', () {
      final full = <String, dynamic>{...data, 'message': 'full message'};
      final truncated = <String, dynamic>{...data, 'message': 'short'};

      final content = ISpectShareLogBottomSheet.buildContent(
        data: full,
        truncatedData: truncated,
        format: ExportFormat.json,
        action: ExportAction.copy,
        metadata: metadata,
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded['message'], equals('short'));
      expect(decoded.containsKey('metadata'), isTrue);
    });

    test('metadata survives the redaction pass', () {
      final content = ISpectShareLogBottomSheet.buildContent(
        data: data,
        truncatedData: data,
        format: ExportFormat.json,
        action: ExportAction.share,
        redactKeys: const {'token', 'password'},
        metadata: metadata,
      );

      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final exportedMeta = decoded['metadata'] as Map<String, dynamic>;
      expect(exportedMeta['appName'], equals('ISpect Quick Start'));
    });

    test('does not mutate the source record maps', () {
      final source = <String, dynamic>{...data};

      ISpectShareLogBottomSheet.buildContent(
        data: source,
        truncatedData: source,
        format: ExportFormat.json,
        action: ExportAction.share,
        metadata: metadata,
      );

      expect(source.containsKey('metadata'), isFalse);
    });
  });
}
