import 'package:dio/dio.dart';
import 'package:ispectify/ispectify.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:test/test.dart';

const _token = 'ghp_abcdefghijklmnopqrstuvwxyz';
const _url = 'https://api.example.test/invite/$_token/accept';

Map<String, dynamic> _meta(ISpectLogData log) =>
    log.additionalData?[TraceKeys.meta] as Map<String, dynamic>;

void main() {
  group('token embedded in a request path', () {
    late ISpectLogger logger;
    late List<ISpectLogData> observed;

    setUp(() {
      ISpectRedaction.reset();
      observed = <ISpectLogData>[];
      logger = ISpectLogger(
        options: ISpectLoggerOptions(useConsoleLogs: false),
      )..addObserver(_CollectingObserver(observed));
    });

    tearDown(() {
      logger.dispose();
      ISpectRedaction.reset();
    });

    test('is masked in history, title, and observer copies', () {
      ISpectDioInterceptor(logger: logger).onRequest(
        RequestOptions(path: _url),
        RequestInterceptorHandler(),
      );

      final log = logger.history.single;
      final requestData =
          _meta(log)[NetworkJsonKeys.requestData] as Map<String, dynamic>;
      expect(log.message, isNot(contains(_token)));
      expect(log.additionalData?[TraceKeys.target], isNot(contains(_token)));
      expect(requestData[NetworkJsonKeys.url], isNot(contains(_token)));
      expect(observed.single.message, isNot(contains(_token)));
    });

    test('stays visible when redaction is explicitly disabled', () {
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(enableRedaction: false),
      ).onRequest(
        RequestOptions(path: _url),
        RequestInterceptorHandler(),
      );

      expect(logger.history.single.message, contains(_token));
    });
  });
}

final class _CollectingObserver extends ISpectObserver {
  _CollectingObserver(this.sink);

  final List<ISpectLogData> sink;

  @override
  void onLog(ISpectLogData data) => sink.add(data);
}
