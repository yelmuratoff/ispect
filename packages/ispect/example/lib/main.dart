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

extension on _HomeState {
  CheckboxListTile buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

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
      ThemeProvider(
        child: App(logger: logger),
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

  // Advanced controls
  String _httpMethod = 'GET';
  bool _useAuthHeader = false;
  int _wsMessageSize = 16; // characters per message
  int _loopDelayMs = 0; // delay between iterations
  bool _randomize = false;
  String _preset = 'Custom';

  @override
  void dispose() {
    _testBloc.close();
    _counterBloc.close();
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
    try {
      throw StateError('Synthetic error for demo');
    } catch (e, st) {
      ISpect.logger.handle(exception: e, stackTrace: st);
    }

    // Trigger real HTTP request/response and error to cover http log types
    final id = (_randomize ? (now.hashCode % 10) + 1 : 1);
    final successPath = '/posts/$id';
    final errorPath = '/invalid-endpoint-$id';
    final headers = <String, String>{
      if (_useAuthHeader) 'Authorization': 'Bearer demo-token',
    };
    dio.options.headers.addAll(headers);
    dio.get<dynamic>(successPath);
    dio.get<dynamic>(errorPath).catchError(
        (e) => Response(requestOptions: RequestOptions(path: errorPath)));
    dio.options.headers.remove('Authorization');

    // Temporary Bloc to trigger create/event/transition/close/state logs
    final tempBloc = CounterBloc();
    tempBloc.add(const Increment());
    tempBloc.add(const Decrement());
    Timer(const Duration(milliseconds: 2), () => tempBloc.close());

    // Riverpod-like logs (synthetic, since riverpod isn't wired here)
    ISpect.logger.log('riverpod add', type: ISpectifyLogType.riverpodAdd);
    ISpect.logger.log('riverpod update', type: ISpectifyLogType.riverpodUpdate);
    ISpect.logger
        .log('riverpod dispose', type: ISpectifyLogType.riverpodDispose);
    ISpect.logger.log('riverpod fail', type: ISpectifyLogType.riverpodFail);
    for (int i = 0; i < _itemCount; i++) {
      ISpect.logger.verbose('Item $i: random=${_randomize && i % 3 == 0}');
      if (_loopDelayMs > 0) {
        unawaited(Future<void>.delayed(Duration(milliseconds: _loopDelayMs)));
      }
    }
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
          dio.get<dynamic>(successPath);
          dio.get<dynamic>(errorPath).catchError(
              (e) => Response(requestOptions: RequestOptions(path: errorPath)));
          break;
        case 'POST':
          dio.post<dynamic>(successPath, data: _mockBody(i));
          dio.post<dynamic>(errorPath, data: _mockBody(i)).catchError(
              (e) => Response(requestOptions: RequestOptions(path: errorPath)));
          break;
        case 'PUT':
          dio.put<dynamic>(successPath, data: _mockBody(i));
          dio.put<dynamic>(errorPath, data: _mockBody(i)).catchError(
              (e) => Response(requestOptions: RequestOptions(path: errorPath)));
          break;
        case 'DELETE':
          dio.delete<dynamic>(successPath);
          dio.delete<dynamic>(errorPath).catchError(
              (e) => Response(requestOptions: RequestOptions(path: errorPath)));
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
            _buildParameterControls(),
            const SizedBox(height: 24),
            _buildActionControls(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parameters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Request Count',
              value: _requestCount.toDouble(),
              min: 1,
              max: 10,
              onChanged: (value) =>
                  setState(() => _requestCount = value.toInt()),
            ),
            _buildSlider(
              label: 'Item Count',
              value: _itemCount.toDouble(),
              min: 10,
              max: 1000,
              onChanged: (value) => setState(() => _itemCount = value.toInt()),
            ),
            _buildSlider(
              label: 'Nesting Depth',
              value: _nestingDepth.toDouble(),
              min: 1,
              max: 10,
              onChanged: (value) =>
                  setState(() => _nestingDepth = value.toInt()),
            ),
            _buildSlider(
              label: 'HTTP Payload Size',
              value: _payloadSize.toDouble(),
              min: 0,
              max: 512,
              onChanged: (value) =>
                  setState(() => _payloadSize = value.toInt()),
            ),
            _buildSlider(
              label: 'WS Message Size',
              value: _wsMessageSize.toDouble(),
              min: 4,
              max: 128,
              onChanged: (value) =>
                  setState(() => _wsMessageSize = value.toInt()),
            ),
            _buildSlider(
              label: 'Delay per Iteration (ms)',
              value: _loopDelayMs.toDouble(),
              min: 0,
              max: 500,
              onChanged: (value) =>
                  setState(() => _loopDelayMs = value.toInt()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _httpMethod,
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: const [
                      DropdownMenuItem(value: 'GET', child: Text('GET')),
                      DropdownMenuItem(value: 'POST', child: Text('POST')),
                      DropdownMenuItem(value: 'PUT', child: Text('PUT')),
                      DropdownMenuItem(value: 'DELETE', child: Text('DELETE')),
                    ],
                    onChanged: (v) => setState(() => _httpMethod = v ?? 'GET'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _preset,
                    decoration: const InputDecoration(labelText: 'Preset'),
                    items: const [
                      DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                      DropdownMenuItem(value: 'Light', child: Text('Light')),
                      DropdownMenuItem(value: 'Stress', child: Text('Stress')),
                      DropdownMenuItem(
                          value: 'Network', child: Text('Network')),
                    ],
                    onChanged: (v) => setState(() {
                      _preset = v ?? 'Custom';
                      _applyPreset(_preset);
                    }),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              value: _useAuthHeader,
              onChanged: (v) => setState(() => _useAuthHeader = v),
              title: const Text('Use Authorization Header'),
              dense: true,
            ),
            SwitchListTile(
              value: _randomize,
              onChanged: (v) => setState(() => _randomize = v),
              title: const Text('Randomize Values'),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildActionGroup(
              title: 'Network',
              icon: Icons.wifi,
              children: [
                buildCheckbox(
                  label: 'HTTP Requests',
                  value: _enableHttp,
                  onChanged: (value) =>
                      setState(() => _enableHttp = value ?? false),
                ),
                buildCheckbox(
                  label: 'WebSocket',
                  value: _enableWs,
                  onChanged: (value) =>
                      setState(() => _enableWs = value ?? false),
                ),
                buildCheckbox(
                  label: 'File Uploads',
                  value: _enableFileUploads,
                  onChanged: (value) =>
                      setState(() => _enableFileUploads = value ?? false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionGroup(
              title: 'Logging',
              icon: Icons.bug_report,
              children: [
                buildCheckbox(
                  label: 'All Log Types',
                  value: _enableLogging,
                  onChanged: (value) =>
                      setState(() => _enableLogging = value ?? false),
                ),
                buildCheckbox(
                  label: 'Analytics',
                  value: _enableAnalytics,
                  onChanged: (value) =>
                      setState(() => _enableAnalytics = value ?? false),
                ),
                buildCheckbox(
                  label: 'Routes',
                  value: _enableRoutes,
                  onChanged: (value) =>
                      setState(() => _enableRoutes = value ?? false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionGroup(
              title: 'State Management',
              icon: Icons.memory,
              children: [
                buildCheckbox(
                  label: 'Bloc Events',
                  value: _enableBlocEvents,
                  onChanged: (value) =>
                      setState(() => _enableBlocEvents = value ?? false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionGroup(
              title: 'Errors',
              icon: Icons.error,
              children: [
                buildCheckbox(
                  label: 'Exceptions',
                  value: _enableExceptions,
                  onChanged: (value) =>
                      setState(() => _enableExceptions = value ?? false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
      _httpMethod = 'GET';
      _useAuthHeader = false;
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

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toInt().toString()),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActionGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

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
        _wsMessageSize = 32;
        _loopDelayMs = 0;
        _randomize = true;
        break;
      default:
        // Custom - leave as is
        break;
    }
  }
}
