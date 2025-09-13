import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/app_localizations.dart';
import 'package:ispect_example/src/cubit/test_cubit.dart';
import 'package:ispect_example/src/theme_manager.dart';
import 'package:ispect_example/src/bloc/counter_bloc.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispectify_http/ispectify_http.dart';
import 'package:ispectify_ws/ispectify_ws.dart';
import 'package:ws/ws.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ispect_example/src/riverpod/riverpod_logging.dart';
import 'package:ispect_example/src/ui/cards/parameters_card.dart';
import 'package:ispect_example/src/ui/cards/network_card.dart';
import 'package:ispect_example/src/ui/cards/logging_card.dart';
import 'package:ispect_example/src/ui/cards/state_management_card.dart';
import 'package:ispect_example/src/ui/cards/error_card.dart';
import 'package:ispect_example/src/ui/cards/stream_card.dart';

// helpers moved into card widgets

final Dio dio = Dio(
  BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  ),
);

final http_interceptor.InterceptedClient client =
    http_interceptor.InterceptedClient.build(interceptors: []);

final Dio dummyDio = Dio(
  BaseOptions(
    baseUrl: 'https://api.escuelajs.co',
  ),
);

void main() {
  final options = ISpectifyOptions(
    logTruncateLength: 500,
  );
  final ISpectify logger = ISpectifyFlutter.init(
    options: options,
    history: DailyFileLogHistory(options),
  );

  ISpect.run(
    () => runApp(
      ProviderScope(
        observers: [ISpectRiverpodObserver()],
        child: ThemeProvider(
          child: App(logger: logger),
        ),
      ),
    ),
    logger: logger,
    isPrintLoggingEnabled: false,
    onInit: () {
      Bloc.observer = ISpecBlocObserver(
        logger: logger,
      );
      client.interceptors.add(
        ISpectHttpInterceptor(logger: logger),
      );
      dio.interceptors.add(
        ISpectDioInterceptor(
          logger: logger,
          settings: const ISpectDioInterceptorSettings(
            printRequestHeaders: true,
          ),
        ),
      );
      dummyDio.interceptors.add(
        ISpectDioInterceptor(
          logger: logger,
        ),
      );
    },
    onInitialized: () {},
  );
}

class App extends StatefulWidget {
  final ISpectify logger;
  const App({super.key, required this.logger});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _controller = DraggablePanelController();
  final _observer = ISpectNavigatorObserver(
    isLogModals: true,
  );

  static const Locale locale = Locale('ru');

  @override
  void initState() {
    super.initState();
    _controller.addPositionListener(
      (x, y) {
        debugPrint('x: $x, y: $y');
      },
    );
    _controller.setPosition(
      x: 500,
      y: 500,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = ThemeProvider.themeMode(context);

    return MaterialApp(
      navigatorObservers: [_observer],
      locale: locale,
      supportedLocales: ExampleGeneratedLocalization.supportedLocales,
      localizationsDelegates: ISpectLocalizations.delegates(delegates: [
        ExampleGeneratedLocalization.delegate,
      ]),
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      builder: (context, child) {
        child = ISpectBuilder(
          theme: const ISpectTheme(
            pageTitle: 'ISpect',
          ),
          observer: _observer,
          controller: _controller,
          options: ISpectOptions(
            locale: locale,
            panelButtons: [
              DraggablePanelButtonItem(
                icon: Icons.copy_rounded,
                label: 'Token',
                description: 'Copy token to clipboard',
                onTap: (context) {
                  _controller.toggle(context);
                  debugPrint('Token copied');
                },
              ),
            ],
            panelItems: [
              DraggablePanelItem(
                icon: Icons.home,
                enableBadge: false,
                description: 'Print home',
                onTap: (context) {
                  debugPrint('Home');
                },
              ),
            ],
            actionItems: [
              ISpectActionItem(
                title: 'Quick log',
                icon: Icons.account_tree_rounded,
                onTap: (context) {
                  ISpect.logger.info('Quick action tapped');
                },
              ),
            ],
          ),
          child: child ?? const SizedBox(),
        );
        return child;
      },
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final TestCubit _testBloc = TestCubit();
  final CounterBloc _counterBloc = CounterBloc();

  // Parameters
  int _requestCount = 1;
  int _itemCount = 100;
  int _nestingDepth = 3;
  int _payloadSize = 64; // bytes approx for POST body mock
  bool _enableHttp = true;
  bool _enableWs = false;
  bool _enableLogging = true;
  bool _enableExceptions = false;
  bool _enableFileUploads = false;
  bool _enableAnalytics = false;
  bool _enableBlocEvents = false;
  bool _enableRoutes = false;
  bool _enableRiverpod = false;
  bool _httpSendSuccess = true;
  bool _httpSendErrors = true;

  // Advanced controls
  String _httpMethod = 'GET';
  bool _useAuthHeader = false;
  int _wsMessageSize = 16; // characters per message
  int _loopDelayMs = 0; // delay between iterations
  bool _randomize = false;
  String _preset = 'Custom';

  // Stream mode
  bool _streamMode = false;
  Timer? _streamTimer;
  int _streamIntervalMs = 1000;

  @override
  void dispose() {
    _testBloc.close();
    _counterBloc.close();
    _stopStream();
    super.dispose();
  }

  void _executeActions() {
    // Optional small delay between groups to visualize order
    Future<void> delay() async {
      if (_loopDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: _loopDelayMs));
      }
    }

    if (_enableLogging) {
      _generateLogs();
    }
    unawaited(delay());
    if (_enableHttp) {
      _generateHttpRequests();
    }
    unawaited(delay());
    if (_enableWs) {
      _generateWebSocketActions();
    }
    unawaited(delay());
    if (_enableExceptions) {
      _generateExceptions();
    }
    unawaited(delay());
    if (_enableFileUploads) {
      _generateFileUploads();
    }
    unawaited(delay());
    if (_enableAnalytics) {
      _generateAnalytics();
    }
    unawaited(delay());
    if (_enableBlocEvents) {
      _generateBlocEvents();
    }
    unawaited(delay());
    if (_enableRoutes) {
      _generateRoutes();
    }
    unawaited(delay());
    if (_enableRiverpod) {
      _generateRiverpod();
    }
  }

  void _toggleStream(bool enabled) {
    setState(() {
      _streamMode = enabled;
    });
    if (enabled) {
      _startStream();
    } else {
      _stopStream();
    }
  }

  void _startStream() {
    _streamTimer?.cancel();
    _streamTimer =
        Timer.periodic(Duration(milliseconds: _streamIntervalMs), (timer) {
      if (!mounted) return;
      _executeActions();
    });
  }

  void _stopStream() {
    _streamTimer?.cancel();
    _streamTimer = null;
  }

  void _generateLogs() {
    final now = DateTime.now().toIso8601String();
    ISpect.logger.good('Demo started at $now');
    ISpect.logger.info('Info: opening Home screen');
    ISpect.logger.debug({'cacheWarmup': true, 'durationMs': 7});
    ISpect.logger.warning('Deprecated API used for demo purposes');
    ISpect.logger.critical('Critical path reached in demo');
    ISpect.logger.provider('Provider: settings updated');
    ISpect.logger.print('Print log example');
    ISpect.logger.route('Route: /demo');
    ISpect.logger.track(
      'Demo analytics',
      analytics: 'demo',
      event: 'open',
      parameters: {'source': 'all-logs', 'time': now},
    );
    // Riverpod logs are generated via _generateRiverpod when enabled

    // Trigger real HTTP request/response and error to cover http log types
    final id = (_randomize ? (now.hashCode % 10) + 1 : 1);
    final successPath = '/posts/$id';
    final errorPath = '/invalid-endpoint-$id';
    final headers = <String, String>{
      if (_useAuthHeader) 'Authorization': 'Bearer demo-token',
    };
    dio.options.headers.addAll(headers);
    if (_httpSendSuccess) {
      dio.get<dynamic>(successPath);
    }
    if (_httpSendErrors) {
      dio.get<dynamic>(errorPath).catchError(
          (e) => Response(requestOptions: RequestOptions(path: errorPath)));
    }
    dio.options.headers.remove('Authorization');

    // Temporary Bloc to trigger create/event/transition/close/state logs
    final tempBloc = CounterBloc();
    tempBloc.add(const Increment());
    tempBloc.add(const Decrement());
    Timer(const Duration(milliseconds: 2), () => tempBloc.close());

    // Riverpod real logs as part of all logs
    _generateRiverpod();

    for (int i = 0; i < _itemCount; i++) {
      ISpect.logger.verbose('Item $i: random=${_randomize && i % 3 == 0}');
      if (_loopDelayMs > 0) {
        unawaited(Future<void>.delayed(Duration(milliseconds: _loopDelayMs)));
      }
    }
  }

  void _generateRiverpod() {
    final container = ProviderContainer(observers: [ISpectRiverpodObserver()]);
    for (int i = 0; i < _itemCount; i++) {
      container.read(counterProvider.notifier).state++;
      container.read(counterNotifierProvider.notifier).increment();
      // Read to produce update
      // ignore: unused_local_variable
      final _ = container.read(counterProvider);
      container.read(counterNotifierProvider);
      // Trigger failing future
      unawaited(
        container
            .read(failingFutureProvider.future)
            .catchError((e, st) => 'failed'),
      );
      if (_loopDelayMs > 0) {
        unawaited(Future<void>.delayed(Duration(milliseconds: _loopDelayMs)));
      }
    }
    container.dispose();
  }

  void _generateHttpRequests() {
    for (int i = 0; i < _requestCount; i++) {
      final id = (_randomize ? (i % 10) + 1 : (i % 10) + 1);
      final successPath = '/posts/$id';
      final errorPath = '/invalid-endpoint-$id';
      final headers = <String, String>{
        if (_useAuthHeader) 'Authorization': 'Bearer demo-token',
      };
      dio.options.headers.addAll(headers);
      switch (_httpMethod) {
        case 'GET':
          if (_httpSendSuccess) {
            dio.get<dynamic>(successPath);
          }
          if (_httpSendErrors) {
            dio.get<dynamic>(errorPath).catchError((e) =>
                Response(requestOptions: RequestOptions(path: errorPath)));
          }
          break;
        case 'POST':
          if (_httpSendSuccess) {
            dio.post<dynamic>(successPath, data: _mockBody(i));
          }
          if (_httpSendErrors) {
            dio.post<dynamic>(errorPath, data: _mockBody(i)).catchError((e) =>
                Response(requestOptions: RequestOptions(path: errorPath)));
          }
          break;
        case 'PUT':
          if (_httpSendSuccess) {
            dio.put<dynamic>(successPath, data: _mockBody(i));
          }
          if (_httpSendErrors) {
            dio.put<dynamic>(errorPath, data: _mockBody(i)).catchError((e) =>
                Response(requestOptions: RequestOptions(path: errorPath)));
          }
          break;
        case 'DELETE':
          if (_httpSendSuccess) {
            dio.delete<dynamic>(successPath);
          }
          if (_httpSendErrors) {
            dio.delete<dynamic>(errorPath).catchError((e) =>
                Response(requestOptions: RequestOptions(path: errorPath)));
          }
          break;
      }
      if (_loopDelayMs > 0) {
        unawaited(Future<void>.delayed(Duration(milliseconds: _loopDelayMs)));
      }
      dio.options.headers.remove('Authorization');
    }
  }

  Map<String, dynamic> _mockBody(int i) {
    final size = _payloadSize.clamp(0, 2048);
    final sb = StringBuffer();
    for (int c = 0; c < size; c++) {
      sb.write(String.fromCharCode(97 + (c % 26)));
    }
    return {
      'id': i,
      'payload': sb.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  void _generateWebSocketActions() {
    const url = 'wss://echo.websocket.events';
    final interceptor = ISpectWSInterceptor(logger: ISpect.logger);
    final client = WebSocketClient(
      WebSocketOptions.common(
        connectionRetryInterval: (
          min: const Duration(milliseconds: 500),
          max: const Duration(seconds: 15),
        ),
        interceptors: [interceptor],
      ),
    );
    interceptor.setClient(client);
    client.connect(url);
    for (int i = 0; i < _itemCount; i++) {
      final msg = _buildWsMessage(i);
      client.add(msg);
      if (_loopDelayMs > 0) {
        unawaited(Future<void>.delayed(Duration(milliseconds: _loopDelayMs)));
      }
    }
    Timer(const Duration(seconds: 2), () => client.close());
  }

  String _buildWsMessage(int i) {
    final len = _wsMessageSize.clamp(1, 512);
    final base = 'Msg#$i-';
    final extraLen = math.max(0, len - base.length);
    final filler = List.generate(
      extraLen,
      (index) =>
          String.fromCharCode(65 + ((_randomize ? (i + index) : index) % 26)),
    ).join();
    return '$base$filler';
  }

  void _generateExceptions() {
    for (int i = 0; i < _requestCount; i++) {
      try {
        throw Exception('Generated exception $i');
      } catch (e, st) {
        ISpect.logger.handle(exception: e, stackTrace: st);
      }
    }
  }

  void _generateFileUploads() {
    for (int i = 0; i < _requestCount; i++) {
      final FormData formData = FormData();
      formData.files.add(MapEntry(
        'file',
        MultipartFile.fromBytes(
          List.generate(_itemCount, (index) => index % 256),
          filename: 'file_$i.txt',
        ),
      ));
      dummyDio.post<dynamic>(
        '/api/v1/files/upload',
        data: formData,
      );
    }
  }

  void _generateAnalytics() {
    for (int i = 0; i < _itemCount; i++) {
      ISpect.logger.track(
        'Analytics event $i',
        analytics: 'demo_analytics',
        event: 'demo_event',
        parameters: {
          'item_id': i,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  void _generateBlocEvents() {
    for (int i = 0; i < _itemCount; i++) {
      if (i % 2 == 0) {
        _counterBloc.add(const Increment());
      } else {
        _counterBloc.add(const Decrement());
      }
      _testBloc.load(data: 'Bloc event data $i');
      if (_loopDelayMs > 0) {
        unawaited(Future<void>.delayed(Duration(milliseconds: _loopDelayMs)));
      }
    }
  }

  void _generateRoutes() {
    for (int i = 0; i < _requestCount; i++) {
      ISpect.logger.route('Demo route $i');
    }
  }

  void _generateNestedData() {
    Map<String, dynamic> nested = {
      'id': _nestingDepth,
      'value': 'Item $_nestingDepth',
    };

    for (int i = _nestingDepth - 1; i >= 0; i--) {
      nested = {'id': i, 'value': 'Item $i', 'nested': nested};
    }

    final Response<dynamic> response = Response(
      requestOptions: RequestOptions(path: '/mock-nested'),
      data: nested,
      statusCode: 200,
    );

    for (final Interceptor interceptor in dio.interceptors) {
      if (interceptor is ISpectDioInterceptor) {
        interceptor.onResponse(response, ResponseInterceptorHandler());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ISpectScopeModel iSpect = ISpect.read(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ExampleGeneratedLocalization.of(context)!.app_title,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => ThemeProvider.toggleTheme(context),
          ),
          IconButton(
            icon: Icon(
              iSpect.isISpectEnabled ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: iSpect.toggleISpect,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ParametersCard(
              requestCount: _requestCount,
              itemCount: _itemCount,
              nestingDepth: _nestingDepth,
              payloadSize: _payloadSize,
              wsMessageSize: _wsMessageSize,
              loopDelayMs: _loopDelayMs,
              httpMethod: _httpMethod,
              preset: _preset,
              useAuthHeader: _useAuthHeader,
              randomize: _randomize,
              onRequestCountChanged: (v) => setState(() => _requestCount = v),
              onItemCountChanged: (v) => setState(() => _itemCount = v),
              onNestingDepthChanged: (v) => setState(() => _nestingDepth = v),
              onPayloadSizeChanged: (v) => setState(() => _payloadSize = v),
              onWsMessageSizeChanged: (v) => setState(() => _wsMessageSize = v),
              onLoopDelayMsChanged: (v) => setState(() => _loopDelayMs = v),
              onHttpMethodChanged: (v) => setState(() => _httpMethod = v),
              onPresetChanged: (v) => setState(() {
                _preset = v;
                _applyPreset(_preset);
              }),
              onUseAuthHeaderChanged: (v) => setState(() => _useAuthHeader = v),
              onRandomizeChanged: (v) => setState(() => _randomize = v),
            ),
            const SizedBox(height: 24),
            NetworkCard(
              enableHttp: _enableHttp,
              httpSendSuccess: _httpSendSuccess,
              httpSendErrors: _httpSendErrors,
              enableWs: _enableWs,
              enableFileUploads: _enableFileUploads,
              onEnableHttpChanged: (v) => setState(() => _enableHttp = v),
              onHttpSendSuccessChanged: (v) =>
                  setState(() => _httpSendSuccess = v),
              onHttpSendErrorsChanged: (v) =>
                  setState(() => _httpSendErrors = v),
              onEnableWsChanged: (v) => setState(() => _enableWs = v),
              onEnableFileUploadsChanged: (v) =>
                  setState(() => _enableFileUploads = v),
            ),
            const SizedBox(height: 16),
            LoggingCard(
              enableLogging: _enableLogging,
              enableAnalytics: _enableAnalytics,
              enableRoutes: _enableRoutes,
              onEnableLoggingChanged: (v) => setState(() => _enableLogging = v),
              onEnableAnalyticsChanged: (v) =>
                  setState(() => _enableAnalytics = v),
              onEnableRoutesChanged: (v) => setState(() => _enableRoutes = v),
            ),
            const SizedBox(height: 16),
            StateManagementCard(
              enableBlocEvents: _enableBlocEvents,
              enableRiverpod: _enableRiverpod,
              onEnableBlocEventsChanged: (v) =>
                  setState(() => _enableBlocEvents = v),
              onEnableRiverpodChanged: (v) =>
                  setState(() => _enableRiverpod = v),
            ),
            const SizedBox(height: 16),
            ErrorCard(
              enableExceptions: _enableExceptions,
              onEnableExceptionsChanged: (v) =>
                  setState(() => _enableExceptions = v),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 16),
            StreamCard(
              streamMode: _streamMode,
              intervalMs: _streamIntervalMs,
              onStreamModeChanged: (v) => _toggleStream(v),
              onIntervalChanged: (v) {
                setState(() => _streamIntervalMs = v);
                if (_streamMode) {
                  _startStream();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Replaced by ParametersCard

  // Replaced by NetworkCard/LoggingCard/StateManagementCard/ErrorCard

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _executeActions,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Execute Actions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generateNestedData,
                icon: const Icon(Icons.data_object),
                label: const Text('Generate Nested Data'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _resetSettings,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Settings'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextButton.icon(
                onPressed: _showInfo,
                icon: const Icon(Icons.info),
                label: const Text('About ISpect'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _resetSettings() {
    setState(() {
      _requestCount = 1;
      _itemCount = 100;
      _nestingDepth = 3;
      _payloadSize = 64;
      _enableHttp = true;
      _enableWs = false;
      _enableLogging = true;
      _enableExceptions = false;
      _enableFileUploads = false;
      _enableAnalytics = false;
      _enableBlocEvents = false;
      _enableRoutes = false;
      _enableRiverpod = false;
      _httpMethod = 'GET';
      _useAuthHeader = false;
      _httpSendSuccess = true;
      _httpSendErrors = true;
      _wsMessageSize = 16;
      _loopDelayMs = 0;
      _randomize = false;
      _preset = 'Custom';
    });
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ISpect'),
        content: const Text(
          'ISpect is a powerful Flutter package for logging, debugging, and monitoring your applications. '
          'This demo showcases various logging types, HTTP interceptors, WebSocket monitoring, and more.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // slider helper moved into ParametersCard

  // Replaced by reusable card widgets

  void _applyPreset(String preset) {
    switch (preset) {
      case 'Light':
        _requestCount = 1;
        _itemCount = 20;
        _nestingDepth = 2;
        _payloadSize = 16;
        _enableHttp = true;
        _enableWs = false;
        _enableLogging = true;
        _enableExceptions = false;
        _enableFileUploads = false;
        _enableAnalytics = false;
        _enableBlocEvents = false;
        _enableRoutes = true;
        _httpMethod = 'GET';
        _useAuthHeader = false;
        _httpSendSuccess = true;
        _httpSendErrors = false;
        _wsMessageSize = 8;
        _loopDelayMs = 0;
        _randomize = false;
        break;
      case 'Stress':
        _requestCount = 10;
        _itemCount = 1000;
        _nestingDepth = 10;
        _payloadSize = 256;
        _enableHttp = true;
        _enableWs = true;
        _enableLogging = true;
        _enableExceptions = true;
        _enableFileUploads = true;
        _enableAnalytics = true;
        _enableBlocEvents = true;
        _enableRoutes = true;
        _httpMethod = 'POST';
        _useAuthHeader = true;
        _httpSendSuccess = true;
        _httpSendErrors = true;
        _wsMessageSize = 64;
        _loopDelayMs = 10;
        _randomize = true;
        break;
      case 'Network':
        _requestCount = 5;
        _itemCount = 50;
        _nestingDepth = 3;
        _payloadSize = 64;
        _enableHttp = true;
        _enableWs = true;
        _enableLogging = false;
        _enableExceptions = false;
        _enableFileUploads = true;
        _enableAnalytics = false;
        _enableBlocEvents = false;
        _enableRoutes = false;
        _httpMethod = 'GET';
        _useAuthHeader = true;
        _httpSendSuccess = true;
        _httpSendErrors = true;
        _wsMessageSize = 32;
        _loopDelayMs = 0;
        _randomize = true;
        break;
      case 'Full':
        _requestCount = 5;
        _itemCount = 200;
        _nestingDepth = 4;
        _payloadSize = 128;
        _enableHttp = true;
        _enableWs = true;
        _enableLogging = true;
        _enableExceptions = true;
        _enableFileUploads = true;
        _enableAnalytics = true;
        _enableBlocEvents = true;
        _enableRoutes = true;
        _enableRiverpod = true;
        _httpMethod = 'POST';
        _useAuthHeader = true;
        _httpSendSuccess = true;
        _httpSendErrors = true;
        _wsMessageSize = 32;
        _loopDelayMs = 5;
        _randomize = true;
        break;
      default:
        // Custom - leave as is
        break;
    }
  }
}
