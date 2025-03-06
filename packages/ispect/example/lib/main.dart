import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/src/core/localization/generated/app_localizations.dart';
import 'package:ispect_example/src/cubit/test_cubit.dart';
import 'package:ispect_example/src/theme_manager.dart';
import 'package:ispectify_bloc/observer.dart';

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
  final iSpectify = ISpectifyFlutter.init();

  ISpect.run(
    () => runApp(
      ThemeProvider(
        child: App(iSpectify: iSpectify),
      ),
    ),
    iSpectify: iSpectify,
    isPrintLoggingEnabled: true,
    onInit: (iSpectify) {
      Bloc.observer = ISpectifyBlocObserver(
        iSpectify: iSpectify,
      );
      client.interceptors.add(
        ISpectifyHttpLogger(iSpectify: ISpect.iSpectify),
      );
      dio.interceptors.add(
        ISpectifyDioLogger(
          iSpectify: ISpect.iSpectify,
          settings: const ISpectifyDioLoggerSettings(
              // errorFilter: (response) {
              //   return (response.message?.contains('This exception was thrown because')) == false;
              // },
              ),
        ),
      );
      dummyDio.interceptors.add(
        ISpectifyDioLogger(
          iSpectify: ISpect.iSpectify,
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
  final _observer = ISpectNavigatorObserver();
  static const locale = Locale('uz');

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
        child = ISpectScopeWrapper(
          options: ISpectOptions(
            locale: locale,
            panelButtons: [
              (
                icon: Icons.copy_rounded,
                label: 'Token',
                onTap: (panelContext) {
                  _controller.toggle(panelContext);
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
          isISpectEnabled: true,
          theme: ISpectTheme(
            logDescriptions: [
              LogDescription(
                key: 'error',
                description: 'Some error log description',
              ),
              LogDescription(
                key: 'info',
                description: 'Blah blah blah',
              ),
              LogDescription(
                key: 'riverpod-add',
                description: 'Riverpod add',
                isDisabled: true,
              ),
            ],
          ),
          child: ISpectBuilder(
            observer: _observer,
            controller: _controller,
            initialPosition: (x: 0, y: 200),
            onPositionChanged: (x, y) {
              debugPrint('x: $x, y: $y');
            },
            child: child,
          ),
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
        title: Text(ExampleGeneratedLocalization.of(context)!.app_title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              BlocBuilder<TestCubit, TestState>(
                bloc: _testBloc,
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: () {
                      _testBloc.load(
                        data: 'Test data',
                      );
                    },
                    child: const Text('Test Cubit'),
                  );
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  await client.get(Uri.parse(
                      'https://jsonplaceholder.typicode.com/posts/1'));
                },
                child: const Text('Send HTTP request (http package)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await client.get(Uri.parse(
                      'https://jsonplaceholder.typicode.com/po2323sts/1'));
                },
                child: const Text('Send error HTTP request (http package)'),
              ),
              ElevatedButton(
                onPressed: () {
                  ThemeProvider.toggleTheme(context);
                },
                child: const Text('Toggle theme'),
              ),
              ElevatedButton(
                onPressed: () {
                  ISpect.track(
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
              ElevatedButton(
                onPressed: () {
                  dio.get('/posts/1');
                },
                child: const Text('Send HTTP request'),
              ),
              ElevatedButton(
                onPressed: () {
                  dio.get('/post3s/1');
                },
                child: const Text('Send HTTP request with error'),
              ),
              ElevatedButton(
                onPressed: () {
                  dio.options.headers.addAll({
                    'Authorization': 'Bearer token',
                  });
                  dio.get('/posts/1');
                  dio.options.headers.remove('Authorization');
                },
                child: const Text('Send HTTP request with Token'),
              ),
              ElevatedButton(
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
              ElevatedButton(
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
              ElevatedButton(
                onPressed: () {
                  throw Exception('Test exception');
                },
                child: const Text('Throw exception'),
              ),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Send print message');
                  //  final logger = CustomLogger('MyApp');
                  //  logger.info('Application started');
                  //  logger.warning('Low disk space');
                  //  logger.error('Unhandled exception occurred');
                },
                child: const Text('Send print message'),
              ),
              ElevatedButton(
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
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const _SecondPage(),
                    ),
                  );
                },
                child: const Text('Replace with second page'),
              ),
              ElevatedButton(
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
        child: ElevatedButton(
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
