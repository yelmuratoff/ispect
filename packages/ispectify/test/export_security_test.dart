import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:test/test.dart';

final class _ThrowingDiagnostic implements Exception {
  const _ThrowingDiagnostic();

  @override
  String toString() => throw StateError('must not escape');
}

final class _ThrowingMapKey {
  const _ThrowingMapKey();

  @override
  String toString() => throw StateError('must not escape');
}

final class _StatefulDiagnostic {
  int calls = 0;

  @override
  String toString() => 'render-${++calls}';
}

String _hostileExportValue() =>
    ''.padRight(LogExportOutput.maxRecordBytes * 2, 'x');

final class _HostileDateTime implements DateTime {
  int calls = 0;

  @override
  String toIso8601String() {
    calls++;
    return _hostileExportValue();
  }

  @override
  String toString() {
    calls++;
    return _hostileExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('DateTime member must not be invoked during export');
  }
}

final class _HostileUri implements Uri {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return _hostileExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Uri member must not be invoked during export');
  }
}

final class _HostileFormatException implements FormatException {
  int calls = 0;

  @override
  Type get runtimeType {
    calls++;
    throw StateError('Exception runtimeType must not be invoked during export');
  }

  @override
  String get message {
    calls++;
    return _hostileExportValue();
  }

  @override
  String toString() {
    calls++;
    return _hostileExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Exception member must not be invoked during export');
  }
}

final class _HostileStateError implements StateError {
  int calls = 0;

  @override
  Type get runtimeType {
    calls++;
    throw StateError('Error runtimeType must not be invoked during export');
  }

  @override
  String get message {
    calls++;
    return _hostileExportValue();
  }

  @override
  String toString() {
    calls++;
    return _hostileExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Error member must not be invoked during export');
  }
}

final class _HostileStackTrace implements StackTrace {
  int calls = 0;

  @override
  Type get runtimeType {
    calls++;
    throw StateError(
      'StackTrace runtimeType must not be invoked during export',
    );
  }

  @override
  String toString() {
    calls++;
    return _hostileExportValue();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('StackTrace member must not be invoked during export');
  }
}

final class _HostileJsonValue {
  int calls = 0;

  Object toJson() {
    calls++;
    return _hostileExportValue();
  }

  @override
  String toString() {
    calls++;
    return _hostileExportValue();
  }
}

final class _HostileLogDataGetters extends ISpectLogData {
  _HostileLogDataGetters()
      : super(
          'trusted-base-message',
          id: 'trusted-base-id',
          time: DateTime.utc(2025),
          key: 'trusted-base-key',
          logLevel: LogLevel.info,
          additionalData: const {'trusted': 'base-data'},
        );

  static const forgedMarker = 'FORGED_GETTER_SECRET';

  final List<int> _getterCalls = [0];

  int get getterCalls => _getterCalls.single;

  Never _forged() {
    _getterCalls[0]++;
    throw StateError(forgedMarker);
  }

  @override
  String get id => _forged();

  @override
  DateTime get time => _forged();

  @override
  String? get key => _forged();

  @override
  LogLevel? get logLevel => _forged();

  @override
  Map<String, dynamic>? get additionalData => _forged();

  @override
  Object? get exception => _forged();

  @override
  Error? get error => _forged();

  @override
  StackTrace? get stackTrace => _forged();

  @override
  String? get message => _forged();

  @override
  Object? get messageForSerialization => _forged();

  @override
  String get formattedTime => _forged();
}

final class _NullRedactionStrategy implements RedactionStrategy {
  const _NullRedactionStrategy();

  @override
  Object? tryRedact(
    Object? node, {
    required RedactionContext context,
    String? keyName,
  }) =>
      null;
}

final class _EnvelopeThrowingScalarIdentityRedactor extends RedactionService {
  @override
  Object? redactEnvelopeForExport(
    Object? data, {
    required Set<String> rootValueKeys,
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      throw StateError('envelope redaction failed');

  @override
  Object? redactForExport(
    Object? data, {
    Set<String>? ignoredValues,
    Set<String>? ignoredKeys,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) =>
      data;
}

void main() {
  tearDown(ISpectRedaction.reset);

  group('safe serialization boundary', () {
    test('toJson safely snapshots cycles and throwing values', () {
      final cyclic = <Object?, Object?>{};
      cyclic['self'] = cyclic;
      cyclic[const _ThrowingMapKey()] = 'secret-behind-unknown-key';
      final log = ISpectLogData(
        'message',
        exception: const _ThrowingDiagnostic(),
        captureMode: DiagnosticCaptureMode.strict,
        additionalData: {'payload': cyclic},
      );

      final json = log.toJson();
      final encoded = jsonEncode(json);

      expect(json['exception'], 'Exception');
      expect(json['exception'], isNot(contains('must not escape')));
      expect(encoded, contains(JsonValueNormalizer.circularReference));
      expect(encoded, isNot(contains('secret-behind-unknown-key')));
    });

    test('toJson never executes hostile formatters and bounds output', () {
      final hostile = _HostileJsonValue();
      final log = ISpectLogData(
        'message',
        captureMode: DiagnosticCaptureMode.strict,
        additionalData: {
          'hostile': hostile,
          'oversized': 'x' * (4 * 1024 * 1024),
        },
      );

      final encoded = jsonEncode(log.toJson());

      expect(hostile.calls, 0);
      expect(encoded, isNot(contains(_hostileExportValue())));
      expect(
        utf8.encode(encoded).length,
        lessThanOrEqualTo(LogExportOutput.maxPreparedValueBytes + 1024),
      );
    });

    test('direct text and Markdown serialization redact by default', () {
      final log = ISpectLogData(
        'failed?token=message-secret',
        additionalData: const {
          'password': 'nested-secret',
        },
      );

      for (final output in [log.toText(), log.toMarkdown()]) {
        expect(output, isNot(contains('message-secret')));
        expect(output, isNot(contains('nested-secret')));
        expect(output, contains(defaultPlaceholder));
      }
    });

    test('direct serialization requires an explicit redaction opt-out', () {
      final log = ISpectLogData(
        'token=raw-message',
        additionalData: const {'password': 'raw-nested'},
      );

      final text = log.toText(enableRedaction: false);
      final markdown = log.toMarkdown(enableRedaction: false);

      expect(text, contains('raw-message'));
      expect(text, contains('raw-nested'));
      expect(markdown, contains('raw-message'));
      expect(markdown, contains('raw-nested'));
    });

    test('typed binary messages are summarized at capture by default', () {
      final raw = Uint16List.fromList(List<int>.filled(32, 60000));
      final log = ISpectLogData(raw);

      expect(log.message, '[binary 64 bytes]');
      for (final output in [
        LogExporter.toJsonLines([log]),
        log.toText(),
        log.toMarkdown(),
      ]) {
        expect(output, isNot(contains('60000')));
        expect(output, contains('binary 64 bytes'));
      }
    });

    test('balanced message capture keeps a bounded readable description', () {
      final diagnostic = _StatefulDiagnostic();
      final log = ISpectLogData(diagnostic);

      expect(log.message, 'render-1');
      expect(log.toJson()['message'], 'render-1');
      expect(
        log.toText(enableRedaction: false),
        contains('render-1'),
      );
      expect(diagnostic.calls, 1);
    });

    test('capture-time redaction opt-out keeps binary provenance opaque', () {
      ISpectRedaction.enabled = false;
      final raw = Int8List.fromList([-1, 2, 3]);

      expect(ISpectLogData(raw).message, '[binary 3 bytes]');
    });

    test('re-enabling redaction masks binary captured during an opt-out', () {
      ISpectRedaction.enabled = false;
      final raw = Uint8List.fromList(List<int>.filled(64, 211));
      final log = ISpectLogData(raw);
      final copied = log.copy();
      ISpectRedaction.enabled = true;

      for (final entry in [log, copied]) {
        final outputs = [
          LogExporter.toJsonLines([entry]),
          entry.toText(),
          entry.toMarkdown(),
          LogExporter.toCsv([entry]),
          entry.toExportMessageText(),
        ];
        for (final output in outputs) {
          expect(output, isNot(contains('211, 211, 211')));
          expect(output, isNot(contains('211,211,211')));
        }
        expect(outputs.first, contains('91,98,105,110,97,114,121'));
      }
    });

    test('text exports redact typed binary exception fields before snapshot',
        () {
      final diagnostics = <Object>[
        Uint16List.fromList(List<int>.filled(32, 60000)),
        Uint8List.fromList(List<int>.filled(64, 211)).buffer,
      ];

      for (final diagnostic in diagnostics) {
        final log = ISpectLogData('failed', exception: diagnostic);
        for (final output in [log.toText(), log.toMarkdown()]) {
          expect(output, isNot(contains('60000')));
          expect(output, isNot(contains('211, 211, 211')));
          expect(output, contains('binary 64 bytes'));
        }
      }
    });
  });

  group('LogExporter redaction policy', () {
    final log = ISpectLogData(
      'failed?token=message-secret',
      key: 'password=key-secret',
      additionalData: const {
        'password': 'nested-secret',
        TraceKeys.category: 'token=category-secret',
      },
    );

    test('all public formats redact by default when keys are omitted', () {
      final outputs = [
        LogExporter.toJsonLines([log]),
        LogExporter.toText([log]),
        LogExporter.toMarkdown([log]),
        LogExporter.toCsv([log]),
      ];

      for (final output in outputs) {
        expect(output, isNot(contains('message-secret')));
        expect(output, isNot(contains('key-secret')));
        expect(output, contains(defaultPlaceholder));
      }
      expect(outputs[0], isNot(contains('nested-secret')));
      expect(outputs[1], isNot(contains('nested-secret')));
      expect(outputs[2], isNot(contains('nested-secret')));
      expect(outputs[3], isNot(contains('category-secret')));
    });

    test('JSONL failure fallback never reuses raw diagnostic fields', () {
      const messageSecret = 'FAILED_ENVELOPE_MESSAGE_SECRET';
      const keySecret = 'FAILED_ENVELOPE_KEY_SECRET';

      final output = LogExporter.toJsonLines(
        [
          ISpectLogData(
            messageSecret,
            key: keySecret,
            time: DateTime(2025),
          ),
        ],
        redactionService: _EnvelopeThrowingScalarIdentityRedactor(),
      );

      expect(output, isNot(contains(messageSecret)));
      expect(output, isNot(contains(keySecret)));
      final decoded = jsonDecode(output) as Map<String, dynamic>;
      expect(decoded['message'], redactionFailedPlaceholder);
      expect(decoded['export-error'], redactionFailedPlaceholder);
      expect(decoded, isNot(contains('key')));
    });

    test('all public formats scrub embedded tokens and JWTs in prose', () {
      const prefixedToken = 'ghp_abcdefghijklmnopqrstuvwxyz';
      const fineGrainedToken =
          'github_pat_abcdefghijklmnopqrstuvwxyz0123456789';
      const jwt = 'aaaaaaaaaaa.bbbbbbbbbbb.ccccccccccc';
      final diagnostic = ISpectLogData(
        'request carried $prefixedToken, $fineGrainedToken, and $jwt',
        additionalData: const {
          'details': 'embedded $prefixedToken, $fineGrainedToken, plus $jwt',
        },
      );
      final outputs = [
        LogExporter.toJsonLines([diagnostic]),
        LogExporter.toText([diagnostic]),
        LogExporter.toMarkdown([diagnostic]),
        LogExporter.toCsv([diagnostic]),
      ];

      for (final output in outputs) {
        expect(output, isNot(contains(prefixedToken)));
        expect(output, isNot(contains(fineGrainedToken)));
        expect(output, isNot(contains(jwt)));
        expect(output, contains(defaultPlaceholder));
      }
    });

    test('all public formats scrub protocol URLs and quoted paths', () {
      final diagnostic = ISpectLogData(
        'request //alice:hunter2@api.test/path?token=PROTOCOL_SECRET '
        "path='/Users/alice/My Project/customer-secret.txt'",
      );
      final outputs = [
        LogExporter.toJsonLines([diagnostic]),
        LogExporter.toText([diagnostic]),
        LogExporter.toMarkdown([diagnostic]),
        LogExporter.toCsv([diagnostic]),
      ];

      for (final output in outputs) {
        expect(output, isNot(contains('alice:hunter2')));
        expect(output, isNot(contains('PROTOCOL_SECRET')));
        expect(output, isNot(contains('My Project')));
        expect(output, isNot(contains('customer-secret.txt')));
        expect(output, contains(defaultPlaceholder));
      }
    });

    test('all public formats honor a supplied custom service', () {
      final customService = RedactionService(
        sensitiveKeys: const {},
        sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
        placeholder: '<CUSTOM_POLICY>',
      );
      final customLog = ISpectLogData(
        'tenantCredential=CUSTOM_FORMAT_SECRET',
        additionalData: const {
          TraceKeys.category: 'tenantCredential=CUSTOM_CATEGORY_SECRET',
        },
      );
      final outputs = [
        LogExporter.toJsonLines(
          [customLog],
          redactKeys: const {'unrelated'},
          redactionService: customService,
        ),
        LogExporter.toText(
          [customLog],
          redactKeys: const {'unrelated'},
          redactionService: customService,
        ),
        LogExporter.toMarkdown(
          [customLog],
          redactKeys: const {'unrelated'},
          redactionService: customService,
        ),
        LogExporter.toCsv(
          [customLog],
          redactKeys: const {'unrelated'},
          redactionService: customService,
        ),
      ];

      for (final output in outputs) {
        expect(output, isNot(contains('CUSTOM_FORMAT_SECRET')));
        expect(output, contains('<CUSTOM_POLICY>'));
      }
      expect(outputs.last, isNot(contains('CUSTOM_CATEGORY_SECRET')));
    });

    test('all public formats use the configured global service', () {
      ISpectRedaction.configure(
        service: RedactionService(
          sensitiveKeys: const {'business_marker'},
          placeholder: '<GLOBAL_POLICY>',
        ),
      );
      final globalLog = ISpectLogData(
        'business_marker=export-secret',
        additionalData: const {'business_marker': 'export-secret'},
      );

      final outputs = [
        LogExporter.toJsonLines([globalLog]),
        LogExporter.toText([globalLog]),
        LogExporter.toMarkdown([globalLog]),
        LogExporter.toCsv([globalLog]),
      ];

      for (final output in outputs) {
        expect(output, isNot(contains('export-secret')));
        expect(output, contains('<GLOBAL_POLICY>'));
      }
    });

    test('all public formats classify quoted JSON keys in messages', () {
      final customService = RedactionService(
        sensitiveKeyPatterns: [RegExp(r'^tenant_credential$')],
      );
      final log = ISpectLogData(
        'access%5Ftoken=ENCODED_FORM_SECRET&safe=visible\n'
        '{"accessToken":"CAMEL_JSON_SECRET",'
        '"tenantCredential":"CUSTOM_JSON_SECRET","safe":"visible"}',
      );
      final outputs = [
        LogExporter.toJsonLines(
          [log],
          redactionService: customService,
        ),
        LogExporter.toText(
          [log],
          redactionService: customService,
        ),
        LogExporter.toMarkdown(
          [log],
          redactionService: customService,
        ),
        LogExporter.toCsv(
          [log],
          redactionService: customService,
        ),
      ];

      for (final output in outputs) {
        expect(output, isNot(contains('CAMEL_JSON_SECRET')));
        expect(output, isNot(contains('CUSTOM_JSON_SECRET')));
        expect(output, isNot(contains('ENCODED_FORM_SECRET')));
        expect(output, contains('visible'));
        expect(output, contains(defaultPlaceholder));
      }
    });

    test('preserves the root log key but redacts nested fields named key', () {
      final output = LogExporter.toJsonLines([
        ISpectLogData(
          'message',
          key: 'test_key_1',
          additionalData: const {
            'nested': {'key': 'nested-secret'},
          },
        ),
      ]);
      final decoded = jsonDecode(output) as Map<String, dynamic>;
      final additional = decoded['additional-data'] as Map<String, dynamic>;
      final nested = additional['nested'] as Map<String, dynamic>;

      expect(decoded['key'], 'test_key_1');
      expect(nested['key'], contains(defaultPlaceholder));
      expect(output, isNot(contains('nested-secret')));
    });

    test('enableRedaction false is an explicit per-export opt-out', () {
      expect(
        LogExporter.toJsonLines([log], enableRedaction: false),
        allOf(
          contains('message-secret'),
          contains('nested-secret'),
        ),
      );
      expect(
        LogExporter.toText([log], enableRedaction: false),
        allOf(
          contains('message-secret'),
          contains('nested-secret'),
        ),
      );
      expect(
        LogExporter.toMarkdown([log], enableRedaction: false),
        allOf(
          contains('message-secret'),
          contains('nested-secret'),
        ),
      );
      expect(
        LogExporter.toCsv([log], enableRedaction: false),
        allOf(
          contains('message-secret'),
          contains('category-secret'),
        ),
      );
    });

    test('the global redaction opt-out is still honored', () {
      ISpectRedaction.enabled = false;

      expect(
        LogExporter.toJsonLines([log]),
        allOf(
          contains('message-secret'),
          contains('nested-secret'),
        ),
      );
    });

    test('metadata values pass through the same default-safe boundary', () {
      final output = LogExporter.toText(
        [ISpectLogData('safe')],
        metadata: const ISpectMetadata(
          extra: {'password': 'metadata-secret'},
        ),
      );

      expect(output, isNot(contains('metadata-secret')));
      expect(output, contains('password: $defaultPlaceholder'));
    });

    test('Markdown metadata cannot escape its blockquote or inject markup', () {
      final output = LogExporter.toMarkdown(
        [ISpectLogData('safe')],
        metadata: const ISpectMetadata(
          extra: {
            'safe\n# injected-heading': 'line\n<img src=x>'
                '\n[link](https://evil.test) ![image](x) @everyone',
          },
        ),
        enableRedaction: false,
      );

      expect(output, isNot(contains('\n# injected-heading')));
      expect(output, isNot(contains('<img')));
      expect(output, isNot(contains('[link](')));
      expect(output, isNot(contains('![image](')));
      expect(output, isNot(contains('@everyone')));
      expect(output, contains('&lt;img src=x&gt;'));
      expect(output, contains('&#64;everyone'));
    });

    test('text metadata redacts typed binary before normalization', () {
      final metadata = ISpectMetadata(
        extra: {
          'diagnosticBytes': Uint8List.fromList(List<int>.filled(64, 122)),
        },
      );

      for (final output in [
        LogExporter.toText([ISpectLogData('safe')], metadata: metadata),
        LogExporter.toMarkdown([ISpectLogData('safe')], metadata: metadata),
      ]) {
        expect(output, isNot(contains(List<int>.filled(12, 122).toString())));
        expect(output, isNot(contains('122, 122, 122')));
        expect(output, contains('[91,98,105,110,97,114,121'));
      }
    });

    test('all public formats redact typed binary payloads by default', () {
      final log = ISpectLogData(
        'binary',
        additionalData: {
          'payload': Uint8List.fromList(List<int>.filled(64, 122)),
        },
      );

      final outputs = [
        LogExporter.toJsonLines([log]),
        LogExporter.toText([log]),
        LogExporter.toMarkdown([log]),
        LogExporter.toCsv([log]),
      ];

      for (final output in outputs) {
        expect(output, isNot(contains(List<int>.filled(12, 122).toString())));
      }
      final json = jsonDecode(outputs.first) as Map<String, dynamic>;
      final additional = json['additional-data'] as Map<String, dynamic>;
      final payload = additional['payload'] as List<dynamic>;
      expect(payload, utf8.encode('[binary 64 bytes]'));
    });

    test('exports redact non-Uint8 typed binary containers', () {
      final log = ISpectLogData(
        'typed binary',
        additionalData: {
          'int8': Int8List.fromList(List<int>.filled(64, 77)),
          'uint16': Uint16List.fromList(List<int>.filled(32, 60000)),
          'byteData': ByteData.view(
            Uint8List.fromList(List<int>.filled(64, 211)).buffer,
          ),
          'buffer': Uint8List.fromList(List<int>.filled(64, 244)).buffer,
        },
      );
      final outputs = [
        LogExporter.toJsonLines([log]),
        LogExporter.toText([log]),
        LogExporter.toMarkdown([log]),
      ];

      for (final output in outputs) {
        expect(output, isNot(contains('77,77,77,77')));
        expect(output, isNot(contains('77, 77, 77, 77')));
        expect(output, isNot(contains('60000')));
        expect(output, isNot(contains('211,211,211,211')));
        expect(output, isNot(contains('211, 211, 211, 211')));
        expect(output, isNot(contains('244,244,244,244')));
        expect(output, isNot(contains('244, 244, 244, 244')));
      }

      final json = jsonDecode(outputs.first) as Map<String, dynamic>;
      final additional = json['additional-data'] as Map<String, dynamic>;
      for (final key in const ['int8', 'uint16', 'byteData', 'buffer']) {
        final payload = additional[key] as List<dynamic>;
        expect(payload, utf8.encode('[binary 64 bytes]'));
      }
    });

    test('explicit export opt-out preserves typed-list values', () {
      final output = LogExporter.toJsonLines(
        [
          ISpectLogData(
            'typed binary',
            additionalData: {
              'int8': Int8List.fromList([-1, 2, 3]),
              'uint16': Uint16List.fromList([256, 512]),
            },
          ),
        ],
        enableRedaction: false,
      );
      final json = jsonDecode(output) as Map<String, dynamic>;
      final additional = json['additional-data'] as Map<String, dynamic>;

      expect(additional['int8'], [-1, 2, 3]);
      expect(additional['uint16'], [256, 512]);
      expect(output, isNot(contains('[binary')));
    });

    test('binary masking cannot be bypassed by a null custom strategy', () {
      final output = LogExporter.toJsonLines(
        [
          ISpectLogData(
            'typed binary',
            additionalData: {
              'payload': Int8List.fromList(List<int>.filled(64, 77)),
            },
          ),
        ],
        redactionService: RedactionService(
          strategy: const _NullRedactionStrategy(),
        ),
      );
      final json = jsonDecode(output) as Map<String, dynamic>;
      final additional = json['additional-data'] as Map<String, dynamic>;
      final payload = additional['payload'] as List<dynamic>;

      expect(payload, utf8.encode('[binary 64 bytes]'));
      expect(payload, isNot(contains(77)));
    });

    test('large typed binary exports use a compact bounded placeholder', () {
      const byteLength = 4 * 1024 * 1024;
      final bytes = Uint8List(byteLength)..fillRange(0, byteLength, 233);
      final output = LogExporter.toJsonLines([
        ISpectLogData(
          'typed binary',
          additionalData: {'payload': bytes.buffer},
        ),
      ]);
      final json = jsonDecode(output) as Map<String, dynamic>;
      final additional = json['additional-data'] as Map<String, dynamic>;

      expect(output.length, lessThan(2048));
      expect(
        additional['payload'],
        '[binary $byteLength bytes]',
      );
      expect(output, isNot(contains('233,233,233')));
    });

    test('redactBinary false preserves typed lists with a custom strategy', () {
      final output = LogExporter.toJsonLines(
        [
          ISpectLogData(
            'typed binary',
            additionalData: {
              'payload': Int8List.fromList([-1, 2, 3]),
            },
          ),
        ],
        redactionService: RedactionService(
          redactBinary: false,
          strategy: const _NullRedactionStrategy(),
        ),
      );
      final json = jsonDecode(output) as Map<String, dynamic>;
      final additional = json['additional-data'] as Map<String, dynamic>;

      expect(additional['payload'], [-1, 2, 3]);
      expect(output, isNot(contains('[binary')));
    });

    test('redactBinary false bounds multi-MiB typed data after redaction', () {
      const byteLength = 4 * 1024 * 1024;
      final bytes = Uint8List(byteLength)..fillRange(0, byteLength, 77);
      final output = LogExporter.toJsonLines(
        [
          ISpectLogData(
            'typed binary',
            additionalData: {'payload': bytes},
          ),
        ],
        redactionService: RedactionService(
          redactBinary: false,
          strategy: const _NullRedactionStrategy(),
        ),
      );
      final decoded = jsonDecode(output) as Map<String, dynamic>;
      final additional = decoded['additional-data'] as Map<String, dynamic>;
      final payload = additional['payload'];

      expect(
        utf8.encode(output).length,
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
      expect(payload, '[binary $byteLength bytes]');
      expect(output.length, lessThan(2048));
      expect(output, isNot(contains('77,77,77')));
    });

    test('all public formats scrub prose secrets and absolute paths', () {
      final log = ISpectLogData(
        'failed password=FORMAT_SECRET '
        'at file:///Users/alice/project/auth.dart:12:3',
      );

      for (final output in [
        LogExporter.toJsonLines([log]),
        LogExporter.toText([log]),
        LogExporter.toMarkdown([log]),
        LogExporter.toCsv([log]),
      ]) {
        expect(output, isNot(contains('FORMAT_SECRET')));
        expect(output, isNot(contains('/Users/alice')));
        expect(output, contains(defaultPlaceholder));
      }
    });
  });

  group('LogExporter output budgets', () {
    test('UTF-8 truncation keeps Unicode scalars intact', () {
      final value = List<String>.filled(20, '🙂é').join();

      for (var maxBytes = 0; maxBytes < 40; maxBytes++) {
        final bounded = LogExportOutput.truncateUtf8(
          value,
          maxBytes: maxBytes,
        );

        expect(utf8.encode(bounded).length, lessThanOrEqualTo(maxBytes));
        expect(() => utf8.decode(utf8.encode(bounded)), returnsNormally);
      }
    });

    test('prepared snapshots charge every synthesized marker to the budget',
        () {
      int retainedStringBytes(Object? value) {
        if (value is String) return utf8.encode(value).length;
        if (value is List<Object?>) {
          return value.fold(
            0,
            (total, element) => total + retainedStringBytes(element),
          );
        }
        if (value is Map<Object?, Object?>) {
          return value.entries.fold(
            0,
            (total, entry) =>
                total +
                retainedStringBytes(entry.key) +
                retainedStringBytes(entry.value),
          );
        }
        return 0;
      }

      final cyclic = <String, Object?>{};
      cyclic['self'] = cyclic;
      final source = {
        'oversized': ''.padRight(1000, 'x'),
        'cycle': cyclic,
        'many': List<Object?>.filled(100, ''.padRight(100, 'y')),
      };
      for (var maxBytes = 0; maxBytes < 80; maxBytes++) {
        final bounded = LogExportOutput.boundJsonValue(
          source,
          maxBytes: maxBytes,
          replaceOversizedStrings: true,
        );

        expect(retainedStringBytes(bounded), lessThanOrEqualTo(maxBytes));
      }
    });

    test('oversized sensitive map keys fail closed before redaction', () {
      const secret = 'OVERSIZED_SENSITIVE_KEY_VALUE_SECRET';
      final sensitiveKey =
          'password.${''.padRight(LogExportOutput.maxPreparedValueBytes, 'k')}';
      final additionalData = <String, dynamic>{
        'safe': 'visible',
        sensitiveKey: secret,
      };
      final log = ISpectLogData(
        'safe',
        additionalData: additionalData,
      );
      final outputs = [
        jsonEncode(
          LogExportOutput.boundJsonValue(
            additionalData,
            replaceOversizedStrings: true,
          ),
        ),
        jsonEncode(log.toExportJson(redactionActive: true)),
        log.toText(),
        log.toMarkdown(),
        LogExporter.toJsonLines([log]),
        LogExporter.toText([log]),
        LogExporter.toMarkdown([log]),
      ];

      for (final output in outputs) {
        expect(output, contains('visible'));
        expect(output, isNot(contains(secret)));
      }
    });

    test('oversized sensitive records fail closed within every format', () {
      const secret = 'OVERSIZED_EXPORT_SECRET';
      final padding = ''.padRight(LogExportOutput.maxRecordBytes * 2, 'x');
      final hugeMessage = 'token=$secret$padding';
      final log = ISpectLogData(hugeMessage);
      final outputs = [
        LogExporter.toJsonLines([log]),
        LogExporter.toText([log]),
        LogExporter.toMarkdown([log]),
        LogExporter.toCsv([log]),
      ];

      for (final output in outputs) {
        expect(
          utf8.encode(output).length,
          lessThanOrEqualTo(LogExportOutput.maxDocumentBytes),
        );
        expect(
          output,
          anyOf(
            contains(LogExportOutput.truncatedMarker),
            contains(defaultPlaceholder),
          ),
        );
        expect(output, isNot(contains(secret)));
      }
      for (final line in const LineSplitter().convert(outputs.first)) {
        expect(() => jsonDecode(line), returnsNormally);
        expect(
          utf8.encode(line).length,
          lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
        );
      }
    });

    test('many records keep every batch format within the aggregate cap', () {
      final message = 'bounded-${''.padRight(200 * 1024, 'x')}';
      final logs = List.generate(
        180,
        (index) => ISpectLogData(
          message,
          time: DateTime(2025).add(Duration(seconds: index)),
        ),
      );
      final formatters = <String, String Function()>{
        'jsonl': () => LogExporter.toJsonLines(
              logs,
              enableRedaction: false,
            ),
        'text': () => LogExporter.toText(
              logs,
              enableRedaction: false,
            ),
        'markdown': () => LogExporter.toMarkdown(
              logs,
              enableRedaction: false,
            ),
        'csv': () => LogExporter.toCsv(
              logs,
              enableRedaction: false,
            ),
      };

      for (final entry in formatters.entries) {
        final output = entry.value();
        expect(
          utf8.encode(output).length,
          lessThanOrEqualTo(LogExportOutput.maxDocumentBytes),
          reason: entry.key,
        );
        if (entry.key != 'jsonl') continue;

        final lines = const LineSplitter().convert(output);
        expect(lines.length, lessThan(logs.length));
        expect(lines.length, greaterThan(100));
        for (final line in lines) {
          expect(() => jsonDecode(line), returnsNormally);
          expect(
            utf8.encode(line).length,
            lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
          );
        }
      }
    });

    test('explicit opt-out keeps only a bounded raw prefix', () {
      const prefix = 'RAW_EXPORT_PREFIX';
      final padding = ''.padRight(LogExportOutput.maxRecordBytes * 2, 'x');
      final log = ISpectLogData(
        '$prefix$padding',
      );

      final output = LogExporter.toJsonLines(
        [log],
        enableRedaction: false,
      );
      final decoded = jsonDecode(output) as Map<String, dynamic>;

      expect(decoded['message'], startsWith(prefix));
      expect(decoded['message'], contains(LogExportOutput.truncatedMarker));
      expect(
        utf8.encode(output).length,
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
    });

    test('active text exports drop previously truncated prefixes', () {
      const partialMessage = 'PARTIAL_EXPORT_MESSAGE';
      const partialData = 'PARTIAL_EXPORT_DATA';
      final log = ISpectLogData(
        '$partialMessage${LogExportOutput.truncatedMarker}',
        additionalData: const {
          'visible': '$partialData${LogExportOutput.truncatedMarker}',
        },
      );

      for (final output in [
        log.toExportMessageText(),
        log.toText(),
        log.toMarkdown(),
        LogExporter.toJsonLines([log]),
      ]) {
        expect(output, isNot(contains(partialMessage)));
        expect(output, isNot(contains(partialData)));
        expect(output, contains(LogExportOutput.truncatedMarker));
      }
    });

    test('single-record serializers are bounded and fail closed by default',
        () {
      const secret = 'SINGLE_RECORD_OUTPUT_SECRET';
      final hugeMessage = 'token=$secret${_hostileExportValue()}';
      final log = ISpectLogData(
        hugeMessage,
        additionalData: {
          'visible': ''.padRight(
            LogExportOutput.maxPreparedValueBytes * 2,
            'd',
          ),
        },
      );

      for (final output in [
        log.toExportMessageText(),
        log.toText(),
        log.toMarkdown(),
      ]) {
        expect(
          utf8.encode(output).length,
          lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
        );
        expect(
          output,
          anyOf(
            contains(LogExportOutput.truncatedMarker),
            contains(defaultPlaceholder),
          ),
        );
        expect(output, isNot(contains(secret)));
      }

      for (final output in [
        log.toExportMessageText(maxOutputBytes: 96),
        log.toText(maxOutputBytes: 96),
        log.toMarkdown(maxOutputBytes: 96),
      ]) {
        expect(utf8.encode(output).length, lessThanOrEqualTo(96));
        expect(output, isNot(contains(secret)));
      }
    });

    test('truncated Markdown never leaves a fenced block open', () {
      final output = ISpectLogData(
        'safe',
        additionalData: {
          'details': ''.padRight(
            LogExportOutput.maxPreparedValueBytes,
            'x',
          ),
        },
      ).toMarkdown(
        enableRedaction: false,
        maxOutputBytes: 512,
      );

      expect(utf8.encode(output).length, lessThanOrEqualTo(512));
      expect(RegExp('```').allMatches(output).length.isEven, isTrue);
      expect(output, startsWith('###'));
      expect(output, contains(LogExportOutput.truncatedMarker));
    });

    test('Markdown data cannot inject additional code fences', () {
      final output = ISpectLogData(
        'message ``` injected',
        key: 'key```value',
        additionalData: const {
          'details': 'value ``` injected',
        },
      ).toMarkdown(enableRedaction: false);

      expect(RegExp('```').allMatches(output).length, 2);
      expect(output, contains('&#96;&#96;&#96;'));
      expect(output, contains(r'\u0060\u0060\u0060'));
    });

    test('Markdown inline fields neutralize active markup and mentions', () {
      const payload = '''visible
# forged heading <img src=x> ![image](https://attacker.invalid/image) [link](https://attacker.invalid) @security-team''';
      final output = ISpectLogData(
        payload,
        key: payload,
      ).toMarkdown(enableRedaction: false);

      expect(RegExp('^#', multiLine: true).allMatches(output), hasLength(1));
      expect(output, isNot(contains('\n# forged heading')));
      expect(output, isNot(contains('<img')));
      expect(output, isNot(contains('![image](')));
      expect(output, isNot(contains('[link](')));
      expect(output, isNot(contains('@security-team')));
      expect(output, contains('# forged heading &lt;img src=x&gt;'));
      expect(
        output,
        contains(
          r'\!\[image\]\(https://attacker.invalid/image\)',
        ),
      );
      expect(
        output,
        contains(r'\[link\]\(https://attacker.invalid\)'),
      );
      expect(output, contains('&#64;security-team'));
      expect(
        utf8.encode(output).length,
        lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
      );
    });

    test('direct serializers never execute caller-controlled formatters', () {
      final hostileException = _HostileFormatException();
      final hostileError = _HostileStateError();
      final hostileStackTrace = _HostileStackTrace();
      final hostileJson = _HostileJsonValue();
      final log = ISpectLogData(
        'safe',
        exception: hostileException,
        error: hostileError,
        stackTrace: hostileStackTrace,
        captureMode: DiagnosticCaptureMode.strict,
        additionalData: {'json': hostileJson},
      );

      final outputs = [
        log.toExportMessageText(),
        log.toText(),
        log.toMarkdown(),
      ];

      for (final output in outputs) {
        expect(
          utf8.encode(output).length,
          lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
        );
      }
      for (final calls in [
        hostileException.calls,
        hostileError.calls,
        hostileStackTrace.calls,
        hostileJson.calls,
      ]) {
        expect(calls, 0);
      }
    });

    test('direct and batch exporters ignore hostile log getter overrides', () {
      final log = _HostileLogDataGetters();

      final directJson = log.toJson();
      final outputs = [
        jsonEncode(directJson),
        log.toExportMessageText(),
        log.toText(),
        log.toMarkdown(),
        LogExporter.toJsonLines([log]),
        LogExporter.toText([log]),
        LogExporter.toMarkdown([log]),
        LogExporter.toCsv([log]),
      ];

      expect(directJson['id'], 'trusted-base-id');
      expect(directJson['message'], 'trusted-base-message');
      expect(log.getterCalls, 0);
      for (final output in outputs) {
        expect(output, isNot(contains(_HostileLogDataGetters.forgedMarker)));
      }
    });

    test('JSONL failure fallback ignores hostile log getter overrides', () {
      final log = _HostileLogDataGetters();

      final output = LogExporter.toJsonLines(
        [log],
        redactionService: _EnvelopeThrowingScalarIdentityRedactor(),
      );

      expect(() => jsonDecode(output), returnsNormally);
      expect(output, contains(redactionFailedPlaceholder));
      expect(output, isNot(contains(_HostileLogDataGetters.forgedMarker)));
      expect(log.getterCalls, 0);
    });

    test('never executes caller formatters before applying output budgets', () {
      final hostileDateTime = _HostileDateTime();
      final hostileUri = _HostileUri();
      final hostileException = _HostileFormatException();
      final hostileError = _HostileStateError();
      final hostileStackTrace = _HostileStackTrace();
      final hostileJson = _HostileJsonValue();
      final log = ISpectLogData(
        'safe',
        exception: hostileException,
        error: hostileError,
        stackTrace: hostileStackTrace,
        captureMode: DiagnosticCaptureMode.strict,
        additionalData: {
          'dateTime': hostileDateTime,
          'uri': hostileUri,
          'json': hostileJson,
        },
      );
      final metadata = ISpectMetadata(
        extra: {
          'dateTime': hostileDateTime,
          'uri': hostileUri,
          'json': hostileJson,
          'exception': hostileException,
          'error': hostileError,
          'stackTrace': hostileStackTrace,
        },
      );

      final outputs = [
        LogExporter.toJsonLines([log]),
        LogExporter.toText([log], metadata: metadata),
        LogExporter.toMarkdown([log], metadata: metadata),
        LogExporter.toCsv([log]),
      ];

      expect(() => jsonDecode(outputs.first), returnsNormally);
      for (final output in outputs) {
        expect(
          utf8.encode(output).length,
          lessThanOrEqualTo(LogExportOutput.maxDocumentBytes),
        );
      }
      for (final calls in [
        hostileDateTime.calls,
        hostileUri.calls,
        hostileException.calls,
        hostileError.calls,
        hostileStackTrace.calls,
        hostileJson.calls,
      ]) {
        expect(calls, 0);
      }
    });

    test('strips oversized private keys before bounded key rewriting', () {
      const privateValue = 'INTERNAL_RENDER_DATA_MUST_NOT_EXPORT';
      final privateKey =
          '_${''.padRight(LogExportOutput.maxPreparedValueBytes * 2, 'x')}';
      final log = ISpectLogData(
        'safe',
        additionalData: {
          privateKey: privateValue,
          'safe': 'visible',
        },
      );

      for (final output in [
        LogExporter.toJsonLines([log]),
        LogExporter.toText([log]),
        LogExporter.toMarkdown([log]),
      ]) {
        expect(output, isNot(contains(privateValue)));
        expect(
          utf8.encode(output).length,
          lessThanOrEqualTo(LogExportOutput.maxRecordBytes),
        );
      }
    });
  });

  group('CSV formula neutralization', () {
    test('neutralizes formula and control prefixes', () {
      expect(LogExporter.escapeCsvValue('=1+1'), "'=1+1");
      expect(LogExporter.escapeCsvValue('+cmd'), "'+cmd");
      expect(LogExporter.escapeCsvValue('-2+3'), "'-2+3");
      expect(LogExporter.escapeCsvValue('@SUM(A1:A2)'), "'@SUM(A1:A2)");
      expect(LogExporter.escapeCsvValue('\t=1+1'), "\"'\t=1+1\"");
      expect(LogExporter.escapeCsvValue('\r+cmd'), "\"'\r+cmd\"");
      expect(LogExporter.escapeCsvValue('\n@cmd'), "\"'\n@cmd\"");
    });

    test('batch CSV uses the shared formula-safe helper', () {
      final output = LogExporter.toCsv([
        ISpectLogData(
          '=HYPERLINK("https://example.test")',
          key: '\t=CMD()',
        ),
      ]);

      expect(output, contains("\"'=HYPERLINK(\"\"https://example.test\"\")\""));
      expect(output, contains("\"'\t=CMD()\""));
    });
  });
}
