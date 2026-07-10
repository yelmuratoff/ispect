import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

void main() {
  group('FileLogHistoryOptions.validate', () {
    const mib = 1024 * 1024;

    final invalidCases = <({FileLogHistoryOptions options, String field})>[
      (
        options: const FileLogHistoryOptions(maxSessionDays: 0),
        field: 'maxSessionDays',
      ),
      (
        options: const FileLogHistoryOptions(maxFileSize: 0),
        field: 'maxFileSize',
      ),
      (
        options: const FileLogHistoryOptions(
          maxTotalSize: 5 * mib - 1,
        ),
        field: 'maxTotalSize',
      ),
      (
        options: const FileLogHistoryOptions(maxBatchItems: 0),
        field: 'maxBatchItems',
      ),
      (
        options: const FileLogHistoryOptions(
          autoSaveInterval: Duration.zero,
        ),
        field: 'autoSaveInterval',
      ),
    ];

    for (final testCase in invalidCases) {
      test('rejects invalid ${testCase.field}', () {
        expect(
          testCase.options.validate,
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              testCase.field,
            ),
          ),
        );
      });
    }

    test('accepts positive lower bounds and an equal total limit', () {
      const options = FileLogHistoryOptions(
        maxSessionDays: 1,
        maxFileSize: 1,
        maxTotalSize: 1,
        maxBatchItems: 1,
        autoSaveInterval: Duration(microseconds: 1),
      );

      expect(options.validate, returnsNormally);
    });
  });

  test('typed failures omit their cause from toString', () {
    const error = FileLogStorageException(
      operation: 'write',
      path: '/managed/history.jsonl',
      cause: 'persisted-content',
    );

    expect(error.toString(), contains('operation: write'));
    expect(error.toString(), contains('/managed/history.jsonl'));
    expect(error.toString(), isNot(contains('persisted-content')));
  });
}
