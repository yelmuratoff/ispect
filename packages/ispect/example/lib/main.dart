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

const String _jsonPlaceholderBaseUrl = 'https://jsonplaceholder.typicode.com';
const String _escuelajsBaseUrl = 'https://api.escuelajs.co';

final dio = Dio(BaseOptions(baseUrl: _jsonPlaceholderBaseUrl));
final client = http_interceptor.InterceptedClient.build(interceptors: []);
final dummyDio = Dio(BaseOptions(baseUrl: _escuelajsBaseUrl));

void main() {
  final iSpectify = ISpectifyFlutter.init(
    options: ISpectifyOptions(logTruncateLength: 500),
  );

  ISpect.run(
    () => runApp(ThemeProvider(child: App(iSpectify: iSpectify))),
    logger: iSpectify,
    isPrintLoggingEnabled: true,
    onInit: () => _setupInterceptors(iSpectify),
  );
}

void _setupInterceptors(ISpectify iSpectify) {
  Bloc.observer = ISpectifyBlocObserver(iSpectify: iSpectify);
  client.interceptors.add(ISpectifyHttpLogger(iSpectify: iSpectify));
  dio.interceptors.add(ISpectifyDioLogger(iSpectify: iSpectify));
  dummyDio.interceptors.add(ISpectifyDioLogger(iSpectify: iSpectify));
}

class App extends StatefulWidget {
  final ISpectify iSpectify;

  const App({super.key, required this.iSpectify});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _controller = DraggablePanelController();
  final _observer = ISpectNavigatorObserver(isLogModals: false);
  static const locale = Locale('uz');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [_observer],
      locale: locale,
      supportedLocales: ExampleGeneratedLocalization.supportedLocales,
      localizationsDelegates: ISpectLocalizations.localizationDelegates([
        ExampleGeneratedLocalization.delegate,
      ]),
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeProvider.themeMode(context),
      builder: (context, child) => _buildWithISpect(context, child),
      home: const _Home(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData.from(
      colorScheme:
          ColorScheme.fromSeed(seedColor: Colors.blue, brightness: brightness),
    );
  }

  Widget _buildWithISpect(BuildContext context, Widget? child) {
    return ISpectBuilder(
      options: ISpectOptions(
        locale: locale,
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
        panelItems: const [
          (
            icon: Icons.home,
            enableBadge: false,
            onTap: _handleHomeTap,
          ),
        ],
        actionItems: const [
          ISpectifyActionItem(
            title: 'Test',
            icon: Icons.account_tree_rounded,
            onTap: _navigateToTestPage,
          ),
        ],
      ),
      theme: ISpectTheme(
        pageTitle: 'Custom Name',
        logDescriptions: [
          LogDescription(key: 'bloc-event', isDisabled: true),
          LogDescription(key: 'bloc-transition', isDisabled: true),
          LogDescription(key: 'bloc-close', isDisabled: true),
          LogDescription(key: 'bloc-create', isDisabled: true),
          LogDescription(key: 'bloc-state', isDisabled: true),
          LogDescription(key: 'riverpod-add', isDisabled: true),
          LogDescription(key: 'riverpod-update', isDisabled: true),
          LogDescription(key: 'riverpod-dispose', isDisabled: true),
          LogDescription(key: 'riverpod-fail', isDisabled: true),
        ],
      ),
      observer: _observer,
      controller: _controller,
      initialPosition: (x: 0, y: 200),
      onPositionChanged: (x, y) => debugPrint('x: $x, y: $y'),
      child: child ?? const SizedBox(),
    );
  }

  static void _handleHomeTap(BuildContext context) => debugPrint('Home');

  static void _navigateToTestPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Scaffold(body: Center(child: Text('Test'))),
      ),
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
  void dispose() {
    _testBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ExampleGeneratedLocalization.of(context)!.app_title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildDemoButtons(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDemoButtons(BuildContext context) {
    final iSpect = ISpect.read(context);

    return [
      _buildButton('Mock Nested Map with Depth IDs', _mockNestedMapWithDepth),
      _buildButton('Mock Large JSON Response', _mockLargeJsonResponse),
      BlocBuilder<TestCubit, TestState>(
        bloc: _testBloc,
        builder: (context, state) {
          return _buildButton(
              'Test Cubit', () => _testBloc.load(data: 'Test data'));
        },
      ),
      _buildButton('Send HTTP request (http package)', _sendHttpRequest),
      _buildButton(
          'Send error HTTP request (http package)', _sendErrorHttpRequest),
      _buildButton('Toggle theme', () => ThemeProvider.toggleTheme(context)),
      _buildButton('Toggle ISpect', () => _toggleISpect(context, iSpect)),
      _buildButton('Send HTTP request', () => dio.get('/posts/1')),
      _buildButton('Send HTTP request with error', () => dio.get('/post3s/1')),
      _buildButton('Send HTTP request with Token', _sendRequestWithToken),
      _buildButton('Upload file to dummy server', _uploadFileToDummyServer),
      _buildButton(
          'Upload file to dummy server (http)', _uploadFileWithHttpClient),
      _buildButton('Throw exception', () => throw Exception('Test exception')),
      _buildButton(
          'Print Large text', () => debugPrint('Print message' * 10000)),
      _buildButton('Go to second page', () => _navigateToSecondPage(context)),
      _buildButton(
          'Replace with second page', () => _replaceWithSecondPage(context)),
    ];
  }

  FilledButton _buildButton(String label, VoidCallback onPressed) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }

  void _toggleISpect(BuildContext context, ISpectScopeModel iSpect) {
    ISpect.logger.track(
      'Toggle',
      analytics: 'amplitude',
      event: 'ISpect',
      parameters: {'isISpectEnabled': iSpect.isISpectEnabled},
    );
    iSpect.toggleISpect();
  }

  void _mockNestedMapWithDepth() {
    const depth = 10000;
    Map<String, dynamic> nested = {'id': depth, 'value': 'Item $depth'};

    for (int i = depth - 1; i >= 0; i--) {
      nested = {'id': i, 'value': 'Item $i', 'nested': nested};
    }

    final response = Response(
      requestOptions: RequestOptions(path: '/mock-nested-id'),
      data: nested,
      statusCode: 200,
    );

    _sendToISpectifyLoggers(response);
  }

  void _mockLargeJsonResponse() {
    final largeMap = _createLargeJsonMap();
    final response = Response(
      requestOptions: RequestOptions(path: '/mock-large-json'),
      data: largeMap,
      statusCode: 200,
    );

    _sendToISpectifyLoggers(response);
  }

  Future<void> _sendHttpRequest() async {
    await client.get(Uri.parse('$_jsonPlaceholderBaseUrl/posts/1'));
  }

  Future<void> _sendErrorHttpRequest() async {
    await client.get(Uri.parse('$_jsonPlaceholderBaseUrl/po2323sts/1'));
  }

  Future<void> _sendRequestWithToken() async {
    try {
      dio.options.headers.addAll({'Authorization': 'Bearer token'});
      await dio.get('/posts/1');
    } finally {
      dio.options.headers.remove('Authorization');
    }
  }

  void _uploadFileToDummyServer() {
    final formData = FormData();
    formData.files.add(MapEntry(
      'file',
      MultipartFile.fromBytes([1, 2, 3], filename: 'file.txt'),
    ));

    dummyDio.post('/api/v1/files/upload', data: formData);
  }

  void _uploadFileWithHttpClient() {
    const filename = 'file.txt';
    final bytes = [1, 2, 3];

    final request = http_interceptor.MultipartRequest(
      'POST',
      Uri.parse('$_escuelajsBaseUrl/api/v1/files/upload'),
    );

    request.files.add(http_interceptor.MultipartFile.fromBytes('file', bytes,
        filename: filename));
    client.send(request);
  }

  void _navigateToSecondPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _SecondPage(),
        settings: const RouteSettings(name: 'SecondPage'),
      ),
    );
  }

  void _replaceWithSecondPage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const _SecondPage()),
    );
  }

  void _sendToISpectifyLoggers(Response response) {
    for (var interceptor in dio.interceptors) {
      if (interceptor is ISpectifyDioLogger) {
        interceptor.onResponse(response, ResponseInterceptorHandler());
      }
    }
  }

  Map<String, dynamic> _createLargeJsonMap() {
    final Map<String, dynamic> largeJsonMap = {
      "apiVersion": "2.0",
      "data": {
        "user": {
          "id": "9876543210",
          "username": "techuser",
          "email": "user@example.com",
          "name": {"first": "John", "last": "Doe", "full": "John Doe"},
          "profile": _generateLargeProfile(),
        },
        "items": _generateLargeItemsList(500),
        "metadata": _generateNestedMetadata(10),
        "analytics": _generateAnalyticsData(),
        "settings": _generateSettings(),
      },
    };
    return largeJsonMap;
  }

  Map<String, dynamic> _generateLargeProfile() {
    final List<Map<String, dynamic>> addresses = List.generate(
      20,
      (i) => {
        "id": "addr_$i",
        "type": i % 3 == 0
            ? "home"
            : i % 3 == 1
                ? "work"
                : "other",
        "street": "123 Test Street $i",
        "city": "Test City $i",
        "state": "TS",
        "zip": "1000$i",
        "country": "Test Country",
        "isDefault": i == 0,
        "coordinates": {
          "latitude": 40.7128 + (i / 100),
          "longitude": -74.0060 - (i / 100)
        },
        "metadata": {
          "createdAt": "2023-01-0$i",
          "updatedAt": "2023-06-${i % 30 + 1}"
        },
      },
    );

    return {
      "avatar": "https://example.com/avatar.jpg",
      "bio": "This is a very long bio text that repeats several times. " * 10,
      "birthdate": "1990-01-01",
      "phone": "+1234567890",
      "website": "https://example.com",
      "socialMedia": {
        "twitter": "@example",
        "facebook": "example.profile",
        "instagram": "example.insta",
        "linkedin": "example-linkedin",
        "github": "example-dev",
        "youtube": "ExampleChannel",
      },
      "preferences": {
        "theme": "dark",
        "notifications": {"email": true, "push": false, "sms": true},
        "privacy": {
          "profileVisibility": "public",
          "activityVisibility": "friends"
        },
        "language": "en",
        "timezone": "UTC-5",
      },
      "addresses": addresses,
      "stats": {
        "followers": 1523,
        "following": 367,
        "posts": 42,
        "likes": 8976,
        "comments": 1243,
        "shares": 523,
        "views": 25467,
      },
    };
  }

  List<Map<String, dynamic>> _generateLargeItemsList(int count) {
    return List.generate(
      count,
      (i) => {
        "id": "item_$i",
        "name": "Product Item $i",
        "description": "This is a detailed description for product $i. " * 3,
        "price": (i * 9.99) % 500 + 0.99,
        "category": "Category ${i % 10}",
        "tags": List.generate(5, (j) => "tag_${(i + j) % 20}"),
        "rating": {
          "average": (i % 5) + (i % 10) / 10,
          "count": i * 7 + 13,
          "distribution": {
            "1": i % 10,
            "2": i % 15,
            "3": i % 25,
            "4": i % 40 + 10,
            "5": i % 50 + 20,
          },
        },
        "stock": {
          "available": i % 3 == 0,
          "quantity": i * 3 + 5,
          "warehouses": List.generate(
            3,
            (w) => {
              "id": "wh_$w",
              "name": "Warehouse $w",
              "quantity": (i + w) * 2,
            },
          ),
        },
        "images": List.generate(
          4,
          (img) => {
            "url": "https://example.com/products/$i/image_$img.jpg",
            "width": 800,
            "height": 600,
            "alt": "Product $i image $img",
          },
        ),
        "createdAt":
            "2023-${(i % 12) + 1}-${(i % 28) + 1}T${i % 24}:${i % 60}:00Z",
        "updatedAt":
            "2023-${(i % 12) + 1}-${(i % 28) + 1}T${i % 24}:${i % 60}:00Z",
      },
    );
  }

  Map<String, dynamic> _generateNestedMetadata(int depth,
      [int currentDepth = 0]) {
    if (currentDepth >= depth) {
      return {
        "finalLevel": true,
        "value": "Reached max depth: $depth",
        "timestamp": DateTime.now().toIso8601String(),
      };
    }

    return {
      "level": currentDepth,
      "name": "Level $currentDepth",
      "description": "This is nested level $currentDepth of $depth",
      "children": List.generate(
        3,
        (i) => _generateNestedMetadata(depth, currentDepth + 1),
      ),
      "properties": {
        "property1": "value_$currentDepth",
        "property2": currentDepth * 100,
        "property3": currentDepth % 2 == 0,
      },
    };
  }

  Map<String, dynamic> _generateAnalyticsData() {
    final List<Map<String, dynamic>> dailyStats = List.generate(
      30,
      (i) => {
        "date": "2023-06-${i + 1}",
        "views": 1000 + (i * 50) + (i % 7) * 100,
        "clicks": 120 + (i * 7) + (i % 5) * 20,
        "conversions": 10 + (i % 10),
        "revenue": (500 + (i * 25) + (i % 3) * 75).toDouble(),
        "bounceRate": 0.3 + (i % 10) / 100,
        "devices": {
          "mobile": 0.6 + (i % 10) / 100,
          "desktop": 0.3 + (i % 10) / 100,
          "tablet": 0.1 - (i % 10) / 100,
        },
      },
    );

    return {
      "summary": {
        "totalViews": 45230,
        "totalClicks": 6820,
        "totalConversions": 420,
        "totalRevenue": 18750.45,
        "avgSessionDuration": "00:03:27",
        "avgPageDepth": 2.7,
      },
      "dailyStats": dailyStats,
      "topReferrers": List.generate(
        10,
        (i) => {
          "domain": "referrer$i.example.com",
          "visits": 1000 - (i * 100),
          "conversionRate": 0.05 - (i * 0.005),
        },
      ),
      "userSegments": List.generate(
        5,
        (i) => {
          "name": "Segment $i",
          "size": 1000 - (i * 150),
          "engagementRate": 0.8 - (i * 0.1),
          "retentionRate": 0.7 - (i * 0.08),
          "demographics": {
            "ageGroups": {
              "18-24": 0.2 + (i * 0.05),
              "25-34": 0.3 - (i * 0.02),
              "35-44": 0.25 + (i * 0.01),
              "45-54": 0.15 - (i * 0.01),
              "55+": 0.1 - (i * 0.005),
            },
            "gender": {"male": 0.48 + (i * 0.02), "female": 0.52 - (i * 0.02)},
            "locations": List.generate(
              5,
              (j) => {
                "country": "Country ${j + i}",
                "percentage": 0.2 - (j * 0.03)
              },
            ),
          },
        },
      ),
    };
  }

  Map<String, dynamic> _generateSettings() {
    final Map<String, dynamic> settings = {};

    // Generate 100 setting categories
    for (int i = 0; i < 100; i++) {
      final categoryName = "category_$i";
      final Map<String, dynamic> categorySettings = {};

      // Each category has 10-20 settings
      final settingsCount = 10 + (i % 11);
      for (int j = 0; j < settingsCount; j++) {
        final settingKey = "setting_${i}_$j";

        // Generate different types of settings
        if (j % 5 == 0) {
          categorySettings[settingKey] = {
            "type": "boolean",
            "value": j % 2 == 0,
            "default": true,
            "description": "This is a boolean setting $j in category $i",
            "allowOverride": j % 3 == 0,
          };
        } else if (j % 5 == 1) {
          categorySettings[settingKey] = {
            "type": "string",
            "value": "value_${i}_$j",
            "default": "default_value",
            "description": "This is a string setting $j in category $i",
            "minLength": 3,
            "maxLength": 50,
          };
        } else if (j % 5 == 2) {
          categorySettings[settingKey] = {
            "type": "number",
            "value": i * 10 + j,
            "default": 0,
            "description": "This is a number setting $j in category $i",
            "min": 0,
            "max": 100,
            "step": 5,
          };
        } else if (j % 5 == 3) {
          categorySettings[settingKey] = {
            "type": "enum",
            "value": "option_${j % 4}",
            "default": "option_0",
            "description": "This is an enum setting $j in category $i",
            "options": ["option_0", "option_1", "option_2", "option_3"],
          };
        } else {
          categorySettings[settingKey] = {
            "type": "object",
            "value": {
              "prop1": "value_$j",
              "prop2": i * j,
              "prop3": j % 2 == 0,
              "prop4": List.generate(5, (k) => "item_$k"),
            },
            "description": "This is an object setting $j in category $i",
          };
        }
      }

      settings[categoryName] = categorySettings;
    }

    return settings;
  }
}

class _SecondPage extends StatelessWidget {
  const _SecondPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => _navigateToHome(context),
          child: const Text('Go to Home'),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const _Home()),
    );
  }
}
