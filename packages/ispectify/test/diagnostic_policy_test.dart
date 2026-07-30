import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('DiagnosticResourceLimits', () {
    test('balanced preserves the 7.0 diagnostic budgets', () {
      const limits = DiagnosticResourceLimits.balanced;

      expect(limits.maxCapturedValueBytes, 256 * 1024);
      expect(limits.maxLogRecordBytes, 1024 * 1024);
      expect(limits.maxExportDocumentBytes, 32 * 1024 * 1024);
      expect(limits.maxTraversalDepth, 64);
      expect(limits.maxTraversalNodes, 10000);
      expect(limits.maxCollectionItems, 1000);
      expect(limits.maxImportCharacters, 32 * 1024 * 1024);
      expect(limits.maxImportBytes, 32 * 1024 * 1024);
      expect(limits.maxImportNodes, 100000);
      expect(limits.maxImportEntries, 100000);
      expect(limits.maxViewerBytes, 1024 * 1024);
      expect(limits.maxViewerNodes, 20000);
      expect(limits.maxClipboardBytes, 100000);
      expect(limits.maxExportEntries, 5000);
      expect(limits.maxExportNodes, 100000);
      expect(limits.maxNetworkHeaders, 100);
      expect(limits.maxNetworkBodyBytes, 128 * 1024);
      expect(limits.maxPendingCorrelations, 1000);
      expect(limits.maxStateTraceBytes, 128 * 1024);
      expect(limits.maxDatabaseScalarBytes, 4 * 1024);
      expect(limits.maxDatabaseDiagnosticsBytes, 16 * 1024);
      expect(limits.maxDatabaseMetadataBytes, 24 * 1024);
      expect(limits.maxUiDiagnosticBytes, 8 * 1024);
      expect(limits.maxSearchQueryBytes, 4096);
      expect(limits.maxConsoleStackTraceFrames, 30);
      expect(limits.validate, returnsNormally);
    });

    test('profiles offer smaller and larger valid budgets', () {
      const constrained = DiagnosticResourceLimits.constrained;
      const balanced = DiagnosticResourceLimits.balanced;
      const extended = DiagnosticResourceLimits.extended;

      expect(
        constrained.maxCapturedValueBytes,
        lessThan(balanced.maxCapturedValueBytes),
      );
      expect(
        extended.maxCapturedValueBytes,
        greaterThan(balanced.maxCapturedValueBytes),
      );
      expect(constrained.validate, returnsNormally);
      expect(extended.validate, returnsNormally);
    });

    test('copyWith changes one budget and preserves the rest', () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxCapturedValueBytes: 512 * 1024,
        maxLogRecordBytes: 2 * 1024 * 1024,
      );

      expect(limits.maxCapturedValueBytes, 512 * 1024);
      expect(limits.maxLogRecordBytes, 2 * 1024 * 1024);
      expect(
        limits.maxExportDocumentBytes,
        DiagnosticResourceLimits.balanced.maxExportDocumentBytes,
      );
      expect(limits.validate, returnsNormally);
    });

    test('custom budgets preserve value equality through map serialization',
        () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxCapturedValueBytes: 512 * 1024,
        maxLogRecordBytes: 2 * 1024 * 1024,
        maxExportDocumentBytes: 64 * 1024 * 1024,
        maxSearchQueryBytes: 8 * 1024,
      );

      final restored = DiagnosticResourceLimits.fromMap(limits.toMap());

      expect(restored, limits);
      expect(restored.hashCode, limits.hashCode);
    });

    test('rejects non-positive and inconsistent budgets at runtime', () {
      expect(
        () => const DiagnosticResourceLimits(
          maxCapturedValueBytes: 0,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const DiagnosticResourceLimits(
          maxCapturedValueBytes: 2048,
          maxLogRecordBytes: 1024,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const DiagnosticResourceLimits(
          maxLogRecordBytes: 2048,
          maxExportDocumentBytes: 1024,
        ).validate(),
        throwsArgumentError,
      );
    });

    test('rejects values above the host-protection ceilings', () {
      expect(
        () => const DiagnosticResourceLimits(
          maxCapturedValueBytes:
              DiagnosticResourceLimits.maxAllowedCapturedValueBytes + 1,
          maxLogRecordBytes:
              DiagnosticResourceLimits.maxAllowedCapturedValueBytes + 1,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const DiagnosticResourceLimits(
          maxTraversalDepth:
              DiagnosticResourceLimits.maxAllowedTraversalDepth + 1,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const DiagnosticResourceLimits(
          maxImportBytes: DiagnosticResourceLimits.maxAllowedImportBytes + 1,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const DiagnosticResourceLimits(
          maxConsoleStackTraceFrames: 0,
        ).validate(),
        throwsArgumentError,
      );
    });
  });

  group('DiagnosticProcessingPolicy', () {
    test('balanced preserves current import and export scheduling', () {
      const policy = DiagnosticProcessingPolicy.balanced;

      expect(policy.exportChunkSize, 50);
      expect(policy.importChunkSize, 25);
      expect(policy.yieldEveryExportChunks, 10);
      expect(policy.yieldEveryImportChunks, 4);
      expect(policy.backgroundProcessingThresholdBytes, 256 * 1024);
      expect(policy.backgroundExportEntryThreshold, 50);
      expect(policy.searchDebounce, const Duration(milliseconds: 300));
      expect(policy.searchYieldInterval, const Duration(milliseconds: 80));
      expect(policy.searchBatchSize, 200);
      expect(policy.largeSearchBatchSize, 120);
      expect(policy.veryLargeSearchBatchSize, 80);
      expect(policy.shortSearchBatchSize, 300);
      expect(policy.viewerBuildYieldThreshold, 1000);
      expect(policy.viewerBuildYieldDelay, const Duration(milliseconds: 5));
      expect(policy.validate, returnsNormally);
    });

    test('responsive and throughput profiles remain valid', () {
      const responsive = DiagnosticProcessingPolicy.responsive;
      const balanced = DiagnosticProcessingPolicy.balanced;
      const throughput = DiagnosticProcessingPolicy.throughput;

      expect(
        responsive.exportChunkSize,
        lessThan(balanced.exportChunkSize),
      );
      expect(
        throughput.exportChunkSize,
        greaterThan(balanced.exportChunkSize),
      );
      expect(responsive.validate, returnsNormally);
      expect(throughput.validate, returnsNormally);
    });

    test('copyWith changes scheduling without resetting other fields', () {
      final policy = DiagnosticProcessingPolicy.balanced.copyWith(
        importChunkSize: 40,
        searchDebounce: const Duration(milliseconds: 175),
      );

      expect(policy.importChunkSize, 40);
      expect(policy.searchDebounce, const Duration(milliseconds: 175));
      expect(
        policy.exportChunkSize,
        DiagnosticProcessingPolicy.balanced.exportChunkSize,
      );
      expect(policy.validate, returnsNormally);
    });

    test('custom scheduling preserves value equality through map serialization',
        () {
      final policy = DiagnosticProcessingPolicy.balanced.copyWith(
        importChunkSize: 40,
        searchDebounce: const Duration(milliseconds: 175),
        viewerBuildYieldDelay: const Duration(milliseconds: 2),
      );

      final restored = DiagnosticProcessingPolicy.fromMap(policy.toMap());

      expect(restored, policy);
      expect(restored.hashCode, policy.hashCode);
    });

    test('rejects disabled yielding and excessive chunk sizes', () {
      expect(
        () => const DiagnosticProcessingPolicy(
          yieldEveryImportChunks: 0,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const DiagnosticProcessingPolicy(
          exportChunkSize: DiagnosticProcessingPolicy.maxAllowedChunkSize + 1,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const DiagnosticProcessingPolicy(
          veryLargeSearchNodeThreshold: 5000,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const DiagnosticProcessingPolicy(
          searchDebounce: Duration(seconds: 11),
        ).validate(),
        throwsArgumentError,
      );
    });
  });

  group('policy integration', () {
    test('logger options preserve policies through copyWith', () {
      const limits = DiagnosticResourceLimits.constrained;
      const processing = DiagnosticProcessingPolicy.responsive;
      final options = ISpectLoggerOptions(
        resourceLimits: limits,
        processingPolicy: processing,
      );

      final updated = options.copyWith(useConsoleLogs: false);

      expect(updated.resourceLimits, same(limits));
      expect(updated.processingPolicy, same(processing));
    });

    test('logger options reject an invalid policy at runtime', () {
      expect(
        () => ISpectLoggerOptions(
          resourceLimits: const DiagnosticResourceLimits(
            maxTraversalNodes: 0,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => ISpectLoggerOptions(
          processingPolicy: const DiagnosticProcessingPolicy(
            importChunkSize: 0,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('log capture honors a custom value budget', () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxCapturedValueBytes: 64,
      );
      final log = ISpectLogData(
        'sensitive diagnostic ${'x' * 200}',
        resourceLimits: limits,
      );

      expect(LogExportOutput.utf8Length(log.message!), lessThanOrEqualTo(64));
      expect(log.message, contains(LogExportOutput.truncatedMarker));
    });

    test('large captured fields are not cut by legacy text defaults', () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxCapturedValueBytes: 64 * 1024,
        maxUiDiagnosticBytes: 32 * 1024,
      );
      const tail = 'TAIL';
      final value = '${'x' * 12000}$tail';
      final log = ISpectLogData(
        value,
        exception: value,
        stackTrace: StackTrace.fromString(value),
        resourceLimits: limits,
      );

      expect(log.messageText, endsWith(tail));
      expect(log.exceptionText, endsWith(tail));
      expect(log.stackTraceText, endsWith(tail));
      expect(
        log.toExportMessageText(enableRedaction: false),
        contains(tail),
      );
    });

    test('console forwarding honors the configured stack-frame budget', () {
      StackTrace? forwardedStackTrace;
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxConsoleStackTraceFrames: 2,
      );
      final logger = ISpectLogger.testing(
        logger: ISpectBaseLogger(
          output: (
            message, {
            logLevel,
            error,
            stackTrace,
            time,
          }) {
            forwardedStackTrace = stackTrace;
          },
        ),
        options: ISpectLoggerOptions(
          useHistory: false,
          forwardErrorToConsole: true,
          resourceLimits: limits,
        ),
      );
      addTearDown(logger.dispose);
      final source = StackTrace.fromString(
        List.generate(5, (index) => '#$index frame-$index').join('\n'),
      );

      logger.handle(exception: Exception('boom'), stackTrace: source);

      final forwarded = forwardedStackTrace.toString();
      expect(forwarded, contains('#0 frame-0'));
      expect(forwarded, contains('#1 frame-1'));
      expect(forwarded, contains('3 more frames'));
      expect(forwarded, isNot(contains('#2 frame-2')));
    });

    test('bounded snapshots honor custom traversal budgets', () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxTraversalDepth: 2,
        maxTraversalNodes: 4,
        maxCollectionItems: 2,
      );

      final bounded = LogExportOutput.boundJsonValue(
        {
          'nested': {
            'deeper': {'value': 1},
          },
          'items': [1, 2, 3],
        },
        resourceLimits: limits,
      );

      expect(
        bounded.toString(),
        anyOf(
          contains(JsonValueNormalizer.maxDepthReached),
          contains(JsonValueNormalizer.maxNodesReached),
          contains(JsonValueNormalizer.maxCollectionItemsReached),
        ),
      );
    });

    test('batch export honors custom record and document budgets', () {
      const limits = DiagnosticResourceLimits(
        maxCapturedValueBytes: 64,
        maxLogRecordBytes: 128,
        maxExportDocumentBytes: 256,
      );
      final logs = List<ISpectLogData>.generate(
        20,
        (index) => ISpectLogData(
          'entry-$index-${'x' * 80}',
          resourceLimits: limits,
        ),
      );

      final output = LogExporter.toJsonLines(logs, resourceLimits: limits);

      expect(
        LogExportOutput.utf8Length(output),
        lessThanOrEqualTo(limits.maxExportDocumentBytes),
      );
      expect(output.split('\n').length, lessThan(logs.length));
    });

    test('single-record formats inherit the captured log budget', () {
      const limits = DiagnosticResourceLimits(
        maxCapturedValueBytes: 64,
        maxLogRecordBytes: 128,
        maxExportDocumentBytes: 256,
      );
      final log = ISpectLogData(
        'entry-${'x' * 200}',
        resourceLimits: limits,
      );

      for (final output in [
        log.toExportMessageText(),
        log.toText(),
        log.toMarkdown(),
      ]) {
        expect(
          LogExportOutput.utf8Length(output),
          lessThanOrEqualTo(limits.maxLogRecordBytes),
        );
      }
    });

    test('UI summaries inherit the captured UI byte budget', () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxUiDiagnosticBytes: 64,
      );
      final log = ISpectLogData(
        'message-${'x' * 200}',
        logLevel: LogLevel.error,
        stackTrace: StackTrace.fromString('trace-${'x' * 200}'),
        resourceLimits: limits,
      );

      expect(
        LogExportOutput.utf8Length(log.generateText()),
        lessThanOrEqualTo(limits.maxUiDiagnosticBytes),
      );
      expect(
        LogExportOutput.utf8Length(log.stackTraceLogText!),
        lessThanOrEqualTo(limits.maxUiDiagnosticBytes),
      );
    });

    test('network map capture honors a custom entry count', () {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxNetworkHeaders: 2,
      );

      final captured = NetworkPayloadSanitizer.toStringKeyMap(
        const {'a': 1, 'b': 2, 'c': 3},
        resourceLimits: limits,
        maxEntries: limits.maxNetworkHeaders,
      );

      expect(captured, {'a': 1, 'b': 2});
    });
  });
}
