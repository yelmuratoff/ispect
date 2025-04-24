import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/app_localizations.dart';
import 'package:ispect_example/src/cubit/test_cubit.dart';
import 'package:ispect_example/src/theme_manager.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

import 'package:ispectify_dio/ispectify_dio.dart';

import 'package:http_interceptor/http_interceptor.dart' as http_interceptor;
import 'package:ispectify_http/ispectify_http.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  ),
);

final client = http_interceptor.InterceptedClient.build(interceptors: []);

final dummyDio = Dio(
  BaseOptions(
    baseUrl: 'https://api.escuelajs.co',
  ),
);

void main() {
  final iSpectify = ISpectifyFlutter.init(
    options: ISpectifyOptions(
      logTruncateLength: 500,
    ),
  );

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
          settings: ISpectifyDioLoggerSettings(
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
    isLogModals: false,
  );

  static const locale = Locale('uz');

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeProvider.themeMode(context);

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
          options: ISpectOptions(
            locale: locale,
            isThemeSchemaEnabled: false,
            panelButtons: [
              (
                icon: Icons.copy_rounded,
                label: 'Token',
                onTap: (context) {
                  _controller.toggle(context);
                  debugPrint('Token copied');
                },
              ),
            ],
            panelItems: [
              (
                icon: Icons.home,
                enableBadge: false,
                onTap: (context) {
                  debugPrint('Home');
                },
              ),
            ],
            actionItems: [
              ISpectifyActionItem(
                title: 'Test',
                icon: Icons.account_tree_rounded,
                onTap: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Scaffold(
                        body: Center(
                          child: Text('Test'),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          theme: ISpectTheme(
            pageTitle: 'Custom Name',
            logDescriptions: [
              LogDescription(
                key: 'bloc-event',
                isDisabled: true,
              ),
              LogDescription(
                key: 'bloc-transition',
                isDisabled: true,
              ),
              LogDescription(
                key: 'bloc-close',
                isDisabled: true,
              ),
              LogDescription(
                key: 'bloc-create',
                isDisabled: true,
              ),
              LogDescription(
                key: 'bloc-state',
                isDisabled: true,
              ),
              LogDescription(
                key: 'riverpod-add',
                isDisabled: true,
              ),
              LogDescription(
                key: 'riverpod-update',
                isDisabled: true,
              ),
              LogDescription(
                key: 'riverpod-dispose',
                isDisabled: true,
              ),
              LogDescription(
                key: 'riverpod-fail',
                isDisabled: true,
              ),
            ],
          ),
          observer: _observer,
          controller: _controller,
          initialPosition: (x: 0, y: 200),
          onPositionChanged: (x, y) {
            debugPrint('x: $x, y: $y');
          },
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
  final _testBloc = TestCubit();
  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ExampleGeneratedLocalization.of(context)!.app_title,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              FilledButton(
                onPressed: () {
                  const depth = 5000;
                  Map<String, dynamic> nested = {
                    'id': depth,
                    'value': 'Item $depth'
                  };

                  for (int i = depth - 1; i >= 0; i--) {
                    nested = {'id': i, 'value': 'Item $i', 'nested': nested};
                  }

                  final response = Response(
                    requestOptions: RequestOptions(path: '/mock-nested-id'),
                    data: nested,
                    statusCode: 200,
                  );
                  for (var interceptor in dio.interceptors) {
                    if (interceptor is ISpectifyDioLogger) {
                      interceptor.onResponse(
                          response, ResponseInterceptorHandler());
                    }
                  }

                  // const depth = 10000;

                  // Map<String, dynamic> nested = {
                  //   'id': depth,
                  //   'value': 'Item $depth',
                  // };

                  // for (int i = depth - 1; i >= 0; i--) {
                  //   nested = {
                  //     'id': i,
                  //     'value': 'Item $i',
                  //     'nested': nested,
                  //   };
                  // }

                  // final largeList = List.generate(
                  //     10000, (index) => {'id': index, 'value': 'Item $index'});

                  // final response = Response(
                  //   requestOptions: RequestOptions(path: '/mock-nested-id'),
                  //   data: largeList,
                  //   statusCode: 200,
                  // );

                  // for (var interceptor in dio.interceptors) {
                  //   if (interceptor is ISpectifyDioLogger) {
                  //     interceptor.onResponse(
                  //         response, ResponseInterceptorHandler());
                  //   }
                  // }
                },
                child: const Text('Mock Nested Map with Depth IDs'),
              ),
              FilledButton(
                onPressed: () {
                  const depth = 10000;

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

                  final largeList = List.generate(
                      10000, (index) => {'id': index, 'value': 'Item $index'});

                  final response = Response(
                    requestOptions: RequestOptions(path: '/mock-nested-id'),
                    data: largeList,
                    statusCode: 200,
                  );

                  for (var interceptor in dio.interceptors) {
                    if (interceptor is ISpectifyDioLogger) {
                      interceptor.onResponse(
                          response, ResponseInterceptorHandler());
                    }
                  }
                },
                child: const Text('Mock Nested List with Depth IDs'),
              ),
              FilledButton(
                onPressed: () {
                  // Print large JSON response
                  final largeList = List.generate(
                      10000, (index) => {'id': index, 'value': 'Item $index'});
                  ISpect.logger.print(largeList.toString());
                },
                child: const Text('Mock Large JSON Response'),
              ),
              BlocBuilder<TestCubit, TestState>(
                bloc: _testBloc,
                builder: (context, state) {
                  return FilledButton(
                    onPressed: () {
                      _testBloc.load(
                        data: 'Test data',
                      );
                    },
                    child: const Text('Test Cubit'),
                  );
                },
              ),
              FilledButton(
                onPressed: () async {
                  await client.get(Uri.parse(
                      'https://jsonplaceholder.typicode.com/posts/1'));
                },
                child: const Text('Send HTTP request (http package)'),
              ),
              FilledButton(
                onPressed: () async {
                  await client.get(Uri.parse(
                      'https://jsonplaceholder.typicode.com/po2323sts/1'));
                },
                child: const Text('Send error HTTP request (http package)'),
              ),
              FilledButton(
                onPressed: () {
                  ThemeProvider.toggleTheme(context);
                },
                child: const Text('Toggle theme'),
              ),
              FilledButton(
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
                child: const Text('Toggle ISpect'),
              ),
              FilledButton(
                onPressed: () {
                  dio.get(
                    '/posts/1',
                  );
                },
                child: const Text('Send HTTP request'),
              ),
              FilledButton(
                onPressed: () {
                  dio.get('/post3s/1');
                },
                child: const Text('Send HTTP request with error'),
              ),
              FilledButton(
                onPressed: () {
                  dio.options.headers.addAll({
                    'Authorization': 'Bearer token',
                  });
                  dio.get('/posts/1');
                  dio.options.headers.remove('Authorization');
                },
                child: const Text('Send HTTP request with Token'),
              ),
              FilledButton(
                onPressed: () {
                  final formData = FormData();
                  formData.files.add(MapEntry(
                    'file',
                    MultipartFile.fromBytes(
                      [1, 2, 3],
                      filename: 'file.txt',
                    ),
                  ));

                  dummyDio.post(
                    '/api/v1/files/upload',
                    data: formData,
                  );
                },
                child: const Text('Upload file to dummy server'),
              ),
              FilledButton(
                onPressed: () {
                  // final formData = FormData();
                  // formData.files.add(MapEntry(
                  //   'file',
                  //   MultipartFile.fromBytes(
                  //     [1, 2, 3],
                  //     filename: 'file.txt',
                  //   ),
                  // ));

                  // dummyDio.post(
                  //   '/api/v1/files/upload',
                  //   data: formData,
                  // );

                  // Prepare the file data
                  final bytes = [1, 2, 3]; // File data as bytes
                  const filename = 'file.txt';

                  // Create the multipart request
                  var request = http_interceptor.MultipartRequest(
                    'POST',
                    Uri.parse('https://api.escuelajs.co/api/v1/files/upload'),
                  );

                  // Add the file to the request
                  request.files.add(http_interceptor.MultipartFile.fromBytes(
                    'file', // Field name
                    bytes,
                    filename: filename,
                  ));

                  // Send the request
                  client.send(request);
                },
                child: const Text('Upload file to dummy server (http)'),
              ),
              FilledButton(
                onPressed: () {
                  throw Exception('Test exception');
                },
                child: const Text('Throw exception'),
              ),
              FilledButton(
                onPressed: () {
                  throw Exception('Test large exception ' * 1000);
                },
                child: const Text('Throw Large exception'),
              ),
              FilledButton(
                onPressed: () {
                  debugPrint('Print message' * 10000);
                },
                child: const Text('Pring Large text'),
              ),
              FilledButton(
                onPressed: () {
                  debugPrint('Send print message');
                },
                child: const Text('Send print message'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const _SecondPage(),
                      settings: const RouteSettings(name: 'SecondPage'),
                    ),
                  );
                },
                child: const Text('Go to second page'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const _SecondPage(),
                    ),
                  );
                },
                child: const Text('Replace with second page'),
              ),
              FilledButton(
                onPressed: () {
                  //  ISpect.logTyped(SuccessLog('Success log'));
                },
                child: const Text('Success log'),
              ),
            ],
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
