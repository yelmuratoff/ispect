import 'package:ispectify/src/utils/bounded_json_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('BoundedJsonDecoder', () {
    test('ignores structural characters inside escaped strings', () {
      const source =
          r'{"message":"escaped quote: \" and delimiters: [{,}]","ok":true}';

      expect(
        BoundedJsonDecoder.decode(source),
        <String, dynamic>{
          'message': 'escaped quote: " and delimiters: [{,}]',
          'ok': true,
        },
      );
    });

    test('reports malformed input without retaining parser source', () {
      const secret = 'PARSER-SOURCE-SECRET';

      try {
        BoundedJsonDecoder.decode('{"token":"$secret",}');
        fail('Expected malformed JSON to be rejected.');
      } on BoundedJsonException catch (error) {
        expect(error.reason, BoundedJsonRejection.malformed);
        expect(error.isLimit, isFalse);
        expect(error.message, BoundedJsonDecoder.rejectedMessage);
        expect(error.source, isNull);
        expect(error.toString(), isNot(contains(secret)));
      }
    });

    test('distinguishes source limits without retaining input', () {
      const secret = 'ENCODED-BYTE-LIMIT-SECRET';
      const source = '"$secret界界"';

      expect(
        () => BoundedJsonDecoder.decode(
          source,
          maxCharacters: source.length,
          maxEncodedBytes: source.length,
        ),
        throwsA(
          isA<BoundedJsonException>()
              .having(
                (error) => error.reason,
                'reason',
                BoundedJsonRejection.encodedByteLimit,
              )
              .having((error) => error.isLimit, 'isLimit', isTrue)
              .having((error) => error.source, 'source', isNull)
              .having(
                (error) => error.toString(),
                'rendered exception',
                isNot(contains(secret)),
              ),
        ),
      );
    });

    test('rejects nesting and breadth during the source preflight', () {
      expect(
        () => BoundedJsonDecoder.decode('[[[0]]]', maxDepth: 2),
        throwsA(
          isA<BoundedJsonException>().having(
            (error) => error.reason,
            'reason',
            BoundedJsonRejection.depthLimit,
          ),
        ),
      );
      expect(
        () => BoundedJsonDecoder.decode(
          '[0,1,2]',
          maxCollectionItems: 2,
        ),
        throwsA(
          isA<BoundedJsonException>().having(
            (error) => error.reason,
            'reason',
            BoundedJsonRejection.collectionLimit,
          ),
        ),
      );
    });

    test('allows a wider root while preserving nested collection limits', () {
      expect(
        BoundedJsonDecoder.decode(
          '[[0,1],[2,3],[4,5]]',
          maxCollectionItems: 2,
          maxRootCollectionItems: 3,
        ),
        <Object?>[
          <Object?>[0, 1],
          <Object?>[2, 3],
          <Object?>[4, 5],
        ],
      );
      expect(
        () => BoundedJsonDecoder.decode(
          '[[0,1,2],[3,4,5],[6,7,8]]',
          maxCollectionItems: 2,
          maxRootCollectionItems: 3,
        ),
        throwsA(
          isA<BoundedJsonException>().having(
            (error) => error.reason,
            'reason',
            BoundedJsonRejection.collectionLimit,
          ),
        ),
      );
    });

    test('rejects excessive approximate nodes before decoding', () {
      expect(
        () => BoundedJsonDecoder.decode(
          '{"one":1,"two":2}',
          maxNodes: 4,
        ),
        throwsA(
          isA<BoundedJsonException>().having(
            (error) => error.reason,
            'reason',
            BoundedJsonRejection.nodeLimit,
          ),
        ),
      );
    });

    test('validates decoded trees iteratively', () {
      final cyclic = <Object?>[];
      cyclic.add(cyclic);

      expect(
        () => BoundedJsonDecoder.validateDecoded(cyclic),
        throwsA(
          isA<BoundedJsonException>().having(
            (error) => error.reason,
            'reason',
            BoundedJsonRejection.malformed,
          ),
        ),
      );
      expect(
        () => BoundedJsonDecoder.validateDecoded(
          <Object?>[
            <Object?>[0],
          ],
          maxDepth: 1,
        ),
        throwsA(
          isA<BoundedJsonException>().having(
            (error) => error.reason,
            'reason',
            BoundedJsonRejection.depthLimit,
          ),
        ),
      );
    });

    test('recognizes complete scalar JSON without classifying plain text', () {
      expect(BoundedJsonDecoder.looksLikeJson(' -12.5e+2 '), isTrue);
      expect(BoundedJsonDecoder.looksLikeJson('null'), isTrue);
      expect(BoundedJsonDecoder.looksLikeJson('404 response'), isFalse);
      expect(BoundedJsonDecoder.looksLikeJson('plain text'), isFalse);
      expect(
        BoundedJsonDecoder.looksLikeJson('[WARN] upstream retry'),
        isFalse,
      );
      expect(BoundedJsonDecoder.looksLikeJson('[WARN]'), isFalse);
      expect(BoundedJsonDecoder.looksLikeJson('{status} ready'), isFalse);
      expect(BoundedJsonDecoder.looksLikeJson('{status}'), isFalse);
      expect(
        BoundedJsonDecoder.looksLikeJson('"hello" said "world"'),
        isFalse,
      );
      expect(BoundedJsonDecoder.looksLikeJson(r'"hello \"world\""'), isTrue);
      expect(BoundedJsonDecoder.looksLikeJson('["valid"]'), isTrue);
      expect(BoundedJsonDecoder.looksLikeJson('{"valid":true}'), isTrue);
    });
  });
}
