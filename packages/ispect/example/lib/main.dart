import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/app_localizations.dart';
import 'package:ispect_example/src/cubit/test_cubit.dart';
import 'package:ispect_example/src/logs_file_example.dart';
import 'package:ispect_example/src/theme_manager.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

import 'package:ispectify_dio/ispectify_dio.dart';

import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispectify_http/ispectify_http.dart';

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
  final ISpectify iSpectify = ISpectifyFlutter.init(
    options: ISpectifyOptions(
      logTruncateLength: 500,
    ),
  );

  // debugRepaintRainbowEnabled = true;

  ISpect.run(
    () => runApp(
      ThemeProvider(
        child: App(iSpectify: iSpectify),
      ),
    ),
    logger: iSpectify,
    isPrintLoggingEnabled: true,
    onInit: () {
      Bloc.observer = ISpectifyBlocObserver(
        iSpectify: iSpectify,
      );
      client.interceptors.add(
        ISpectifyHttpLogger(iSpectify: iSpectify),
      );
      dio.interceptors.add(
        ISpectifyDioLogger(
          iSpectify: iSpectify,
          settings: const ISpectifyDioLoggerSettings(
            printRequestHeaders: true,
            // requestFilter: (requestOptions) =>
            //     requestOptions.path != '/post3s/1',
            // responseFilter: (response) => response.statusCode != 404,
            // errorFilter: (response) => response.response?.statusCode != 404,
            // errorFilter: (response) {
            //   return (response.message?.contains('This exception was thrown because')) == false;
            // },
          ),
        ),
      );
      dummyDio.interceptors.add(
        ISpectifyDioLogger(
          iSpectify: iSpectify,
        ),
      );
    },
    onInitialized: () {},
  );
}

class App extends StatefulWidget {
  final ISpectify iSpectify;
  const App({super.key, required this.iSpectify});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _controller = DraggablePanelController();
  final _observer = ISpectNavigatorObserver(
    isLogModals: true,
  );

  static const Locale locale = Locale('en');

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
      localizationsDelegates: ISpectLocalizations.localizationDelegates([
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
          initialPosition: (x: 0, y: 200),
          onPositionChanged: (x, y) {
            debugPrint('x: $x, y: $y');
          },
          options: ISpectOptions(
            locale: locale,
            // isThemeSchemaEnabled: false,

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
                title: 'Test',
                icon: Icons.account_tree_rounded,
                onTap: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Test'),
                        ),
                        body: const Center(
                          child: Text('Test'),
                        ),
                      ),
                    ),
                  );
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

typedef _ButtonConfig = ({String label, VoidCallback onPressed});

class _HomeState extends State<_Home> {
  final TestCubit _testBloc = TestCubit();

  @override
  void dispose() {
    _testBloc.close();
    super.dispose();
  }

  List<_ButtonConfig> _buildButtonConfigs(
    BuildContext context,
    ISpectScopeModel iSpect,
  ) {
    return <_ButtonConfig>[
      (
        label: 'Mock Nested Map with Depth IDs',
        onPressed: () {
          const int depth = 5000;
          Map<String, dynamic> nested = {
            'id': depth,
            'value': 'Item $depth',
          };

          for (int i = depth - 1; i >= 0; i--) {
            nested = {'id': i, 'value': 'Item $i', 'nested': nested};
          }

          final Response<dynamic> response = Response(
            requestOptions: RequestOptions(path: '/mock-nested-id'),
            data: nested,
            statusCode: 200,
          );
          for (final Interceptor interceptor in dio.interceptors) {
            if (interceptor is ISpectifyDioLogger) {
              interceptor.onResponse(response, ResponseInterceptorHandler());
            }
          }
        },
      ),
      (
        label: 'Mock Nested List with Depth IDs',
        onPressed: () {
          const int depth = 10000;

          Map<String, dynamic> nested = {
            'id': depth,
            'value': 'Item $depth',
          };

          for (int i = depth - 1; i >= 0; i--) {
            nested = {
              'id': i,
              'value': 'Item $i',
              'nested': nested,
            };
          }

          final List<Map<String, dynamic>> largeList = List.generate(
              10000, (index) => {'id': index, 'value': 'Item $index'});

          final Response<dynamic> response = Response(
            requestOptions: RequestOptions(path: '/mock-nested-id'),
            data: largeList,
            statusCode: 200,
          );

          for (final Interceptor interceptor in dio.interceptors) {
            if (interceptor is ISpectifyDioLogger) {
              interceptor.onResponse(response, ResponseInterceptorHandler());
            }
          }
        },
      ),
      (
        label: 'Mock Large JSON Response',
        onPressed: () {
          final List<Map<String, dynamic>> largeList = List.generate(
              10000, (index) => {'id': index, 'value': 'Item $index'});
          ISpect.logger.print(largeList.toString());
        },
      ),
      (
        label: 'Test Cubit',
        onPressed: () {
          _testBloc.load(
            data: 'Test data',
          );
        },
      ),
      (
        label: 'Send HTTP request (http package)',
        onPressed: () async {
          await client
              .get(Uri.parse('https://jsonplaceholder.typicode.com/posts/1'));
        },
      ),
      (
        label: 'Send error HTTP request (http package)',
        onPressed: () async {
          await client.get(
              Uri.parse('https://jsonplaceholder.typicode.com/po2323sts/1'));
        },
      ),
      (
        label: 'Toggle theme',
        onPressed: () {
          ThemeProvider.toggleTheme(context);
        },
      ),
      (
        label: 'Toggle ISpect',
        onPressed: () {
          ISpect.logger.track(
            'Toggle',
            analytics: 'amplitude',
            event: 'ISpect',
            parameters: {
              'isISpectEnabled': iSpect.isISpectEnabled,
            },
          );
          iSpect.toggleISpect();
        },
      ),
      (
        label: 'Send HTTP request',
        onPressed: () {
          dio.get<dynamic>(
            '/posts/1',
          );
        },
      ),
      (
        label: 'Send HTTP request with error',
        onPressed: () {
          dio.get<dynamic>('/post3s/1');
        },
      ),
      (
        label: 'Send HTTP request with Token',
        onPressed: () {
          dio.options.headers.addAll({
            'Authorization': 'Bearer token',
          });
          dio.get<dynamic>('/posts/1');
          dio.options.headers.remove('Authorization');
        },
      ),
      (
        label: 'Upload file to dummy server',
        onPressed: () {
          final FormData formData = FormData();
          formData.files.add(MapEntry(
            'file',
            MultipartFile.fromBytes(
              [1, 2, 3],
              filename: 'file.txt',
            ),
          ));

          dummyDio.post<dynamic>(
            '/api/v1/files/upload',
            data: formData,
          );
        },
      ),
      (
        label: 'Upload file to dummy server (http)',
        onPressed: () {
          final List<int> bytes = [1, 2, 3]; // File data as bytes
          const String filename = 'file.txt';

          final http_interceptor.MultipartRequest request =
              http_interceptor.MultipartRequest(
            'POST',
            Uri.parse('https://api.escuelajs.co/api/v1/files/upload'),
          );

          request.files.add(http_interceptor.MultipartFile.fromBytes(
            'file', // Field name
            bytes,
            filename: filename,
          ));

          client.send(request);
        },
      ),
      (
        label: 'Throw exception',
        onPressed: () {
          throw Exception('Test exception');
        },
      ),
      (
        label: 'Go to second page',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _SecondPage(),
              settings: const RouteSettings(name: 'SecondPage'),
            ),
          );
        },
      ),
      (
        label: 'Log 10000 items',
        onPressed: () {
          for (int i = 0; i < 10000; i++) {
            ISpect.logger.info('Item $i');
          }
        },
      ),
      (
        label: 'Logs File',
        onPressed: () async {
          await LogsFileExample.createAndHandleLogsFile();
          await LogsFileExample.createMultipleLogsFiles();
          await LogsFileExample.demonstrateCleanup();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ISpectScopeModel iSpect = ISpect.read(context);
    final List<_ButtonConfig> buttonConfigs =
        _buildButtonConfigs(context, iSpect);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ExampleGeneratedLocalization.of(context)!.app_title,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buttonConfigs.expand(
              (config) {
                final Widget button = FilledButton(
                  onPressed: config.onPressed,
                  child: Text(config.label),
                );
                if (config.label == 'Test Cubit') {
                  return [
                    BlocBuilder<TestCubit, TestState>(
                      bloc: _testBloc,
                      builder: (context, state) => FilledButton(
                        onPressed: config.onPressed,
                        child: Text(config.label),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ];
                }
                return [
                  button,
                  const SizedBox(height: 10),
                ];
              },
            ).toList()
              ..removeLast(),
          ),
        ),
      ),
    );
  }
}

class _SecondPage extends StatelessWidget {
  const _SecondPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const _Home(),
              ),
            );
          },
          child: const Text('Go to Home'),
        ),
      ),
    );
  }
}
