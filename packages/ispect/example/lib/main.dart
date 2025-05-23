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
            // isThemeSchemaEnabled: false,
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
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: Text('Test'),
                        ),
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
                  Map<String, dynamic> nested = {
                    "count": 661,
                    "next":
                        "https://mobile-dev.astanahub.com/api/vacancy/?page=2&page_size=10",
                    "previous": null,
                    "results": [
                      {
                        "id": 1207,
                        "author": {
                          "id": 55806,
                          "first_name": "АЙДАР",
                          "last_name": "СЫДЫКОВ",
                          "full_name": "АЙДАР СЫДЫКОВ",
                          "thumbnail_url": "",
                          "avatar_letters": "А",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": {
                          "id": 3946,
                          "name":
                              "Товарищество с ограниченной ответственностью CloudSaver",
                          "short_name":
                              "Товарищество с ограниченной ответственностью CloudSaver",
                          "tin": "100010001000"
                        },
                        "title": {
                          "en": "Лаборатория",
                          "kk": "Лаборатория",
                          "ru": "Лаборатория"
                        },
                        "specializations": [],
                        "vacancy_type": "fulltime",
                        "salary_min": 12,
                        "salary_max": 23,
                        "place": "flexible_schedule",
                        "city": {"id": 16, "name": "Жезказган"},
                        "short_description": {"en": "", "kk": "", "ru": ""},
                        "email": "a.sydykov@astanahub.com",
                        "comment": "",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1207",
                        "author_name":
                            "Товарищество с ограниченной ответственностью CloudSaver",
                        "author_logo": "",
                        "created_at": "2025-05-14T16:09:39.627801+05:00",
                        "view_count": 32,
                        "is_favorite": false,
                        "opened": true,
                        "region": "shymkent",
                        "additional_place": ["flexible_schedule"],
                        "education": "bachelor_degree",
                        "experience": "at_least_2_years",
                        "direction": "accounting_finance",
                        "published_at": "2025-05-14T16:10:27+05:00",
                        "vacancy_applied": true,
                        "candidate_status": "viewed",
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": 5512,
                        "updated_at": "2025-05-19T18:08:37.887237+05:00",
                        "recruiter_enabled": false
                      },
                      {
                        "id": 1204,
                        "author": {
                          "id": 58521,
                          "first_name": "Yelaman",
                          "last_name": "jkhjg",
                          "full_name": "Yelaman jkhjg",
                          "thumbnail_url": "",
                          "avatar_letters": "Y",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": {
                          "id": 3188,
                          "name": "ТОО QUANT TECH",
                          "short_name": "ТОО QUANT TECH",
                          "tin": "190740034640"
                        },
                        "title": {"en": "Test", "kk": "Test", "ru": "Test"},
                        "specializations": [],
                        "vacancy_type": "fulltime",
                        "salary_min": 0,
                        "salary_max": 500000,
                        "place": null,
                        "city": null,
                        "short_description": {"en": "", "kk": "", "ru": ""},
                        "email": "e99xxx@gmail.com",
                        "comment": "",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1204",
                        "author_name": "ТОО QUANT TECH",
                        "author_logo":
                            "/media/quant-logo_5-5166b9896018-thumbnail-210.png",
                        "created_at": "2025-04-23T12:39:45.205598+05:00",
                        "view_count": 14,
                        "is_favorite": false,
                        "opened": true,
                        "region": "astana",
                        "additional_place": [
                          "onsite",
                          "shift_schedule",
                          "remote"
                        ],
                        "education": "bachelor_degree",
                        "experience": "at_least_1_year",
                        "direction": "administrative_staff",
                        "published_at": "2025-04-23T15:38:39+05:00",
                        "vacancy_applied": false,
                        "candidate_status": null,
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": null,
                        "updated_at": "2025-05-21T12:02:59.177965+05:00",
                        "recruiter_enabled": true
                      },
                      {
                        "id": 1197,
                        "author": {
                          "id": 56194,
                          "first_name": "ӘЛИХАН",
                          "last_name": "СҮЛЕЙМЕН",
                          "full_name": "ӘЛИХАН СҮЛЕЙМЕН",
                          "thumbnail_url": "",
                          "avatar_letters": "Ә",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": {
                          "id": 1,
                          "name": "Beeline",
                          "short_name": "Beeline",
                          "tin": "14054043332"
                        },
                        "title": {
                          "en": "Название вакансии",
                          "kk": "Название вакансии",
                          "ru": "Название вакансии"
                        },
                        "specializations": [],
                        "vacancy_type": "parttime",
                        "salary_min": 100000,
                        "salary_max": 200000,
                        "place": null,
                        "city": null,
                        "short_description": {"en": "", "kk": "", "ru": ""},
                        "email": "drakhimzhanov@gmail.com",
                        "comment": "описание вакансии не полное",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1197",
                        "author_name": "Beeline",
                        "author_logo":
                            "/media/02-Beeline.png-e60acd04edfd-thumbnail-210.png",
                        "created_at": "2025-03-31T10:16:36.442185+05:00",
                        "view_count": 76,
                        "is_favorite": false,
                        "opened": true,
                        "region": "atyrau",
                        "additional_place": ["onsite", "remote"],
                        "education": "master_degree",
                        "experience": "from_1_to_3_years",
                        "direction": "career_begin_students",
                        "published_at": "2025-03-31T10:21:32+05:00",
                        "vacancy_applied": false,
                        "candidate_status": null,
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": null,
                        "updated_at": "2025-05-16T10:46:53.155686+05:00",
                        "recruiter_enabled": false
                      },
                      {
                        "id": 1193,
                        "author": {
                          "id": 55806,
                          "first_name": "АЙДАР",
                          "last_name": "СЫДЫКОВ",
                          "full_name": "АЙДАР СЫДЫКОВ",
                          "thumbnail_url": "",
                          "avatar_letters": "А",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": {
                          "id": 3946,
                          "name":
                              "Товарищество с ограниченной ответственностью CloudSaver",
                          "short_name":
                              "Товарищество с ограниченной ответственностью CloudSaver",
                          "tin": "100010001000"
                        },
                        "title": {
                          "en": "Test Vacancy",
                          "kk": "Test Vacancy",
                          "ru": "Test Vacancy"
                        },
                        "specializations": [],
                        "vacancy_type": "fulltime",
                        "salary_min": 100000,
                        "salary_max": 200000,
                        "place": null,
                        "city": null,
                        "short_description": {"en": "", "kk": "", "ru": ""},
                        "email": "a.sydykov@astanahub.com",
                        "comment": "",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1193",
                        "author_name":
                            "Товарищество с ограниченной ответственностью CloudSaver",
                        "author_logo": "",
                        "created_at": "2025-03-19T11:49:04.549038+05:00",
                        "view_count": 72,
                        "is_favorite": false,
                        "opened": true,
                        "region": "astana",
                        "additional_place": ["onsite"],
                        "education": "bachelor_degree",
                        "experience": "at_least_2_years",
                        "direction": "information_technology",
                        "published_at": "2025-03-19T11:49:48+05:00",
                        "vacancy_applied": false,
                        "candidate_status": null,
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": null,
                        "updated_at": "2025-05-14T15:23:29.032054+05:00",
                        "recruiter_enabled": false
                      },
                      {
                        "id": 1191,
                        "author": {
                          "id": 55806,
                          "first_name": "АЙДАР",
                          "last_name": "СЫДЫКОВ",
                          "full_name": "АЙДАР СЫДЫКОВ",
                          "thumbnail_url": "",
                          "avatar_letters": "А",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": {
                          "id": 3946,
                          "name":
                              "Товарищество с ограниченной ответственностью CloudSaver",
                          "short_name":
                              "Товарищество с ограниченной ответственностью CloudSaver",
                          "tin": "100010001000"
                        },
                        "title": {
                          "en": "Testing Event",
                          "kk": "Testing Event",
                          "ru": "Testing Event"
                        },
                        "specializations": [],
                        "vacancy_type": "parttime",
                        "salary_min": 12,
                        "salary_max": 1234,
                        "place": null,
                        "city": null,
                        "short_description": {"en": "", "kk": "", "ru": ""},
                        "email": "a@a.com",
                        "comment": "",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1191",
                        "author_name":
                            "Товарищество с ограниченной ответственностью CloudSaver",
                        "author_logo": "",
                        "created_at": "2025-03-13T12:29:37.321269+05:00",
                        "view_count": 81,
                        "is_favorite": false,
                        "opened": true,
                        "region": "aktobe",
                        "additional_place": ["shift_schedule"],
                        "education": "bachelor_degree",
                        "experience": "at_least_3_years",
                        "direction": "top_management",
                        "published_at": "2025-03-13T12:31:52.293814+05:00",
                        "vacancy_applied": false,
                        "candidate_status": null,
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": null,
                        "updated_at": "2025-03-13T12:29:37.321302+05:00",
                        "recruiter_enabled": false
                      },
                      {
                        "id": 1180,
                        "author": {
                          "id": 55806,
                          "first_name": "АЙДАР",
                          "last_name": "СЫДЫКОВ",
                          "full_name": "АЙДАР СЫДЫКОВ",
                          "thumbnail_url": "",
                          "avatar_letters": "А",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": {
                          "id": 3946,
                          "name":
                              "Товарищество с ограниченной ответственностью CloudSaver",
                          "short_name":
                              "Товарищество с ограниченной ответственностью CloudSaver",
                          "tin": "100010001000"
                        },
                        "title": {
                          "en": "QA Tester",
                          "kk": "QA Tester",
                          "ru": "QA Tester"
                        },
                        "specializations": [],
                        "vacancy_type": "fulltime",
                        "salary_min": 1,
                        "salary_max": 2,
                        "place": null,
                        "city": null,
                        "short_description": {"en": "", "kk": "", "ru": ""},
                        "email": "a@a.com",
                        "comment": "",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1180",
                        "author_name":
                            "Товарищество с ограниченной ответственностью CloudSaver",
                        "author_logo": "",
                        "created_at": "2025-02-04T11:51:08.594540+05:00",
                        "view_count": 90,
                        "is_favorite": false,
                        "opened": true,
                        "region": "astana",
                        "additional_place": ["onsite"],
                        "education": "bachelor_degree",
                        "experience": "at_least_3_years",
                        "direction": "information_technology",
                        "published_at": "2025-02-04T11:52:38.377581+05:00",
                        "vacancy_applied": false,
                        "candidate_status": null,
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": null,
                        "updated_at": "2025-02-04T11:51:08.594561+05:00",
                        "recruiter_enabled": false
                      },
                      {
                        "id": 1175,
                        "author": {
                          "id": 55806,
                          "first_name": "АЙДАР",
                          "last_name": "СЫДЫКОВ",
                          "full_name": "АЙДАР СЫДЫКОВ",
                          "thumbnail_url": "",
                          "avatar_letters": "А",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": null,
                        "title": {"en": "", "kk": "", "ru": "ascascas"},
                        "specializations": ["string"],
                        "vacancy_type": "fulltime",
                        "salary_min": 21,
                        "salary_max": 2147,
                        "place": "onsite",
                        "city": null,
                        "short_description": {"ru": "axcaX"},
                        "email": "ascasc@example.com",
                        "comment": "",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1175",
                        "author_name": "АЙДАР СЫДЫКОВ",
                        "author_logo": "",
                        "created_at": "2025-01-29T18:16:41.252489+05:00",
                        "view_count": 49,
                        "is_favorite": false,
                        "opened": true,
                        "region": null,
                        "additional_place": [
                          "onsite",
                          "shift_schedule",
                          "flexible_schedule",
                          "shift_method"
                        ],
                        "education": "",
                        "experience": "at_least_2_years",
                        "direction": "transport_logistics",
                        "published_at": null,
                        "vacancy_applied": true,
                        "candidate_status": "new",
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": 5754,
                        "updated_at": "2025-01-30T09:21:05.265734+05:00",
                        "recruiter_enabled": false
                      },
                      {
                        "id": 1172,
                        "author": {
                          "id": 55806,
                          "first_name": "АЙДАР",
                          "last_name": "СЫДЫКОВ",
                          "full_name": "АЙДАР СЫДЫКОВ",
                          "thumbnail_url": "",
                          "avatar_letters": "А",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": null,
                        "title": {"en": "", "kk": "", "ru": ""},
                        "specializations": ["string"],
                        "vacancy_type": "fulltime",
                        "salary_min": 2147483647,
                        "salary_max": 2147483647,
                        "place": "onsite",
                        "city": null,
                        "short_description": {},
                        "email": "user@example.com",
                        "comment": "",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1172",
                        "author_name": "АЙДАР СЫДЫКОВ",
                        "author_logo": "",
                        "created_at": "2025-01-29T10:53:46.259013+05:00",
                        "view_count": 39,
                        "is_favorite": false,
                        "opened": true,
                        "region": null,
                        "additional_place": ["string"],
                        "education": "",
                        "experience": "string",
                        "direction": "string",
                        "published_at": null,
                        "vacancy_applied": false,
                        "candidate_status": null,
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": null,
                        "updated_at": "2025-01-29T10:53:46.259032+05:00",
                        "recruiter_enabled": false
                      },
                      {
                        "id": 1162,
                        "author": {
                          "id": 55806,
                          "first_name": "АЙДАР",
                          "last_name": "СЫДЫКОВ",
                          "full_name": "АЙДАР СЫДЫКОВ",
                          "thumbnail_url": "",
                          "avatar_letters": "А",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": null,
                        "title": {"en": "", "kk": "", "ru": ""},
                        "specializations": ["string"],
                        "vacancy_type": "fulltime",
                        "salary_min": 2147483647,
                        "salary_max": 2147483647,
                        "place": "onsite",
                        "city": null,
                        "short_description": {},
                        "email": "user@example.com",
                        "comment": "",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1162",
                        "author_name": "АЙДАР СЫДЫКОВ",
                        "author_logo": "",
                        "created_at": "2025-01-29T08:58:06.049144+05:00",
                        "view_count": 39,
                        "is_favorite": false,
                        "opened": true,
                        "region": null,
                        "additional_place": ["string"],
                        "education": "",
                        "experience": "string",
                        "direction": "string",
                        "published_at": null,
                        "vacancy_applied": false,
                        "candidate_status": null,
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": null,
                        "updated_at": "2025-01-29T08:58:06.049171+05:00",
                        "recruiter_enabled": false
                      },
                      {
                        "id": 1153,
                        "author": {
                          "id": 55806,
                          "first_name": "АЙДАР",
                          "last_name": "СЫДЫКОВ",
                          "full_name": "АЙДАР СЫДЫКОВ",
                          "thumbnail_url": "",
                          "avatar_letters": "А",
                          "games_blacklist": false,
                          "organization": {
                            "name": "КФ АстанаХаб",
                            "name_dict": {
                              "en": "KF Astana Hub",
                              "kk": "КК АстанаХаб",
                              "ru": "КФ АстанаХаб"
                            },
                            "logo":
                                "https://mobile-dev.astanahub.com/media/organizations/photo_2022-01-28_10-31-18-56112bd8e247-thumbnail-210.png"
                          }
                        },
                        "company": null,
                        "title": {"en": "", "kk": "", "ru": ""},
                        "specializations": ["string"],
                        "vacancy_type": "fulltime",
                        "salary_min": 2147483647,
                        "salary_max": 2147483647,
                        "place": "onsite",
                        "city": null,
                        "short_description": {},
                        "email": "user@example.com",
                        "comment": "",
                        "status": "success",
                        "absolute_url":
                            "https://dev.astanahub.com/ru/vacancy/1153",
                        "author_name": "АЙДАР СЫДЫКОВ",
                        "author_logo": "",
                        "created_at": "2025-01-28T19:38:04.181361+05:00",
                        "view_count": 38,
                        "is_favorite": false,
                        "opened": true,
                        "region": null,
                        "additional_place": ["string"],
                        "education": "",
                        "experience": "string",
                        "direction": "string",
                        "published_at": null,
                        "vacancy_applied": false,
                        "candidate_status": null,
                        "rejected_by_seeker": false,
                        "rejected_by_recruiter": false,
                        "candidate_id": null,
                        "updated_at": "2025-01-28T19:38:04.181387+05:00",
                        "recruiter_enabled": false
                      }
                    ]
                  };

                  final response = Response(
                    requestOptions:
                        RequestOptions(path: '/mock-nested-real-json'),
                    data: nested,
                    statusCode: 200,
                  );

                  for (var interceptor in dio.interceptors) {
                    if (interceptor is ISpectifyDioLogger) {
                      interceptor.onResponse(
                          response, ResponseInterceptorHandler());
                    }
                  }
                },
                child: const Text('Mock Nested Real JSON'),
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
