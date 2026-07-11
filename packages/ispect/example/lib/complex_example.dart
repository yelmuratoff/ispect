import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/interceptors/ws_interceptor.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:ispectify_db/ispectify_db.dart';
import 'package:ispectify_dio/ispectify_dio.dart';
import 'package:ispectify_http/ispectify_http.dart';
import 'package:ispectify_riverpod/ispectify_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ws/ws.dart';

// ---------------------------------------------------------------------------
// Observer example
// ---------------------------------------------------------------------------

class SentryISpectObserver implements ISpectObserver {
  @override
  void onError(ISpectLogData data) => log('Sentry onError: ${data.message}');
  @override
  void onException(ISpectLogData data) =>
      log('Sentry onException: ${data.message}');
  @override
  void onLog(ISpectLogData data) => log('Sentry onLog: ${data.message}');
}

// ---------------------------------------------------------------------------
// Theme presets
// ---------------------------------------------------------------------------

class _ThemePreset {
  const _ThemePreset(this.label, this.seed, this.primary, this.background);
  final String label;
  final Color seed;
  final ISpectDynamicColor? primary;
  final ISpectDynamicColor? background;
}

const _themePresets = <_ThemePreset>[
  _ThemePreset('Default', Colors.deepPurple, null, null),
  _ThemePreset(
    'Ocean',
    Colors.blue,
    ISpectDynamicColor(light: Color(0xFF1565C0), dark: Color(0xFF64B5F6)),
    ISpectDynamicColor(light: Color(0xFFF5F8FF), dark: Color(0xFF0D1B2A)),
  ),
  _ThemePreset(
    'Forest',
    Colors.green,
    ISpectDynamicColor(light: Color(0xFF2E7D32), dark: Color(0xFF81C784)),
    ISpectDynamicColor(light: Color(0xFFF1F8E9), dark: Color(0xFF1B2E1B)),
  ),
  _ThemePreset(
    'Sunset',
    Colors.deepOrange,
    ISpectDynamicColor(light: Color(0xFFD84315), dark: Color(0xFFFF8A65)),
    ISpectDynamicColor(light: Color(0xFFFFF3E0), dark: Color(0xFF2E1A0E)),
  ),
  _ThemePreset(
    'Mono',
    Colors.grey,
    ISpectDynamicColor(light: Color(0xFF424242), dark: Color(0xFFBDBDBD)),
    ISpectDynamicColor(light: Color(0xFFFAFAFA), dark: Color(0xFF121212)),
  ),
];

// ---------------------------------------------------------------------------
// Locales
// ---------------------------------------------------------------------------

class _LocaleOption {
  const _LocaleOption(this.locale, this.label);
  final Locale locale;
  final String label;
}

const _localeOptions = <_LocaleOption>[
  _LocaleOption(Locale('en'), 'English'),
  _LocaleOption(Locale('ru'), 'Русский'),
  _LocaleOption(Locale('kk'), 'Қазақша'),
  _LocaleOption(Locale('de'), 'Deutsch'),
  _LocaleOption(Locale('es'), 'Español'),
  _LocaleOption(Locale('fr'), 'Français'),
  _LocaleOption(Locale('pt'), 'Português'),
  _LocaleOption(Locale('zh'), '中文'),
  _LocaleOption(Locale('ja'), '日本語'),
  _LocaleOption(Locale('ko'), '한국어'),
  _LocaleOption(Locale('hi'), 'हिन्दी'),
  _LocaleOption(Locale('ar'), 'العربية'),
];

// ---------------------------------------------------------------------------
// Riverpod providers (real, no codegen) — wired through ISpectRiverpodObserver
// ---------------------------------------------------------------------------

/// Simple counter — exercises didAddProvider + didUpdateProvider + didDispose.
final _counterProvider = StateProvider<int>((ref) => 0, name: 'counter');

/// Throws on init — exercises providerDidFail (and didAddProvider with
/// `value: null`, per Riverpod's contract).
final _failingProvider = Provider<int>(
  (ref) => throw StateError('demo: provider init failed'),
  name: 'failing',
);

/// Family parameter shows up as `argument` in the trace meta, useful for
/// verifying redaction and multi-instance handling.
final _userNameProvider = Provider.family<String, int>(
  (ref, userId) => 'user-$userId',
  name: 'user-name',
);

/// Async provider whose future throws — exercises providerDidFail after the
/// initial didAddProvider with `AsyncValue.loading`.
final _flakyFutureProvider = FutureProvider<String>(
  (ref) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    throw const FormatException('demo: malformed payload');
  },
  name: 'flaky-future',
);

// ---------------------------------------------------------------------------
// BLoC (real, no codegen) — wired through ISpectBlocObserver
// ---------------------------------------------------------------------------

sealed class CounterEvent {
  const CounterEvent();
}

final class CounterIncremented extends CounterEvent {
  const CounterIncremented();
}

final class CounterDecremented extends CounterEvent {
  const CounterDecremented();
}

final class CounterReset extends CounterEvent {
  const CounterReset();
}

/// Reports a recoverable error via `addError` — exercises onError (bloc-error)
/// without crashing the bloc, so the demo stays interactive.
final class CounterFailed extends CounterEvent {
  const CounterFailed();
}

/// Counter bloc exercising the full observer surface: onCreate, onEvent,
/// onTransition, onChange, onError, onDone, and onClose.
final class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterIncremented>((_, emit) => emit(state + 1));
    on<CounterDecremented>((_, emit) => emit(state - 1));
    on<CounterReset>((_, emit) => emit(0));
    on<CounterFailed>(
      (_, __) => addError(
        StateError('demo: counter operation failed'),
        StackTrace.current,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

void main() {
  ISpect.run(
    () => runApp(
      ProviderScope(
        observers: [ISpectRiverpodObserver(logger: ISpect.logger)],
        child: const MyApp(),
      ),
    ),
    logger: ISpectFlutter.init(
      options: ISpectLoggerOptions(maxHistoryItems: 10000),
      fileHistory: const FileLogHistoryOptions(
        maxSessionDays: 7,
        maxFileSize: 5 * 1024 * 1024,
        maxTotalSize: 50 * 1024 * 1024,
      ),
      // observer: SentryISpectObserver(),
    ),
    onInit: () => Bloc.observer = ISpectBlocObserver(logger: ISpect.logger),
  );
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _observer = ISpectNavigatorObserver();

  ThemeMode _themeMode = ThemeMode.system;
  _ThemePreset _preset = _themePresets.first;
  Locale _locale = const Locale('en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      showPerformanceOverlay: false,
      debugShowCheckedModeBanner: false,
      supportedLocales: _localeOptions.map((o) => o.locale),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...ISpectLocalizations.delegate(),
      ],
      navigatorObservers:
          ISpectNavigatorObserver.observers(observer: _observer),
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _preset.seed,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _preset.seed,
          brightness: Brightness.dark,
        ),
      ),
      builder: (_, child) => ISpectBuilder.wrap(
        child: child!,
        options: ISpectOptions(
          observer: _observer,
          enableJankLogging: true,
          onSettingsChanged: (settings) {
            ISpect.logger.log('Settings changed: ${settings.toString()}',
                additionalData: settings.toMap());
          },
          onOpenFile: (path) async => OpenFilex.open(path),
          onShare: (req) async => SharePlus.instance.share(ShareParams(
            text: req.text,
            subject: req.subject,
            files: req.filePaths.map(XFile.new).toList(),
          )),
          // Demo stub for the HTTP composer's multipart "attach file". A real
          // app wires file_picker / image_picker here; this returns a canned
          // in-memory file so the flow is testable without a native picker.
          onPickComposerFile: () async => ComposerPickedFile(
            filename: 'sample.txt',
            bytes: utf8.encode('Hello from the ISpect HTTP composer'),
            contentType: 'text/plain',
          ),
        ),
        theme: ISpectTheme(
          primary: _preset.primary,
          background: _preset.background,
        ),
      ),
      home: _HomePage(
        themeMode: _themeMode,
        preset: _preset,
        locale: _locale,
        onThemeModeChanged: (v) => setState(() => _themeMode = v),
        onPresetChanged: (v) => setState(() => _preset = v),
        onLocaleChanged: (v) => setState(() => _locale = v),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page
// ---------------------------------------------------------------------------

class _HomePage extends StatefulWidget {
  const _HomePage({
    required this.themeMode,
    required this.preset,
    required this.locale,
    required this.onThemeModeChanged,
    required this.onPresetChanged,
    required this.onLocaleChanged,
  });

  final ThemeMode themeMode;
  final _ThemePreset preset;
  final Locale locale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<_ThemePreset> onPresetChanged;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  // Stress test
  double _logCount = 10;
  double _listSize = 5;
  double _nestingDepth = 2;
  bool _isGenerating = false;

  // All log types
  bool _isGeneratingAllTypes = false;

  // Periodic logger
  Timer? _periodicTimer;
  int _periodicCounter = 0;

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISpect Example'),
        actions: [
          // Theme mode
          IconButton(
            icon: Icon(switch (widget.themeMode) {
              ThemeMode.light => Icons.light_mode,
              ThemeMode.dark => Icons.dark_mode,
              ThemeMode.system => Icons.settings_brightness,
            }),
            onPressed: () {
              const modes = ThemeMode.values;
              final next =
                  modes[(modes.indexOf(widget.themeMode) + 1) % modes.length];
              widget.onThemeModeChanged(next);
            },
            tooltip: 'Theme: ${widget.themeMode.name}',
          ),
          // Locale
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: 'Language',
            onSelected: widget.onLocaleChanged,
            itemBuilder: (_) => [
              for (final opt in _localeOptions)
                PopupMenuItem(
                  value: opt.locale,
                  child: Text(opt.label),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Status
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    kISpectEnabled ? Icons.check_circle : Icons.cancel,
                    color: cs.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ISpect ${kISpectEnabled ? "ENABLED" : "DISABLED"}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Color presets
          _SectionHeader(title: 'Color Preset'),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _themePresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = _themePresets[i];
                final selected = widget.preset.label == p.label;
                return ChoiceChip(
                  label: Text(p.label),
                  avatar: CircleAvatar(backgroundColor: p.seed, radius: 8),
                  selected: selected,
                  onSelected: (_) => widget.onPresetChanged(p),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Quick logs
          _SectionHeader(title: 'Quick Logs'),
          const SizedBox(height: 8),
          _QuickLogsGrid(),
          const SizedBox(height: 20),

          // All log types
          _SectionHeader(title: 'All Log Types'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isGeneratingAllTypes ? null : _generateAllLogTypes,
            icon: _isGeneratingAllTypes
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.list_alt),
            label: const Text('Generate one log per every type'),
          ),
          const SizedBox(height: 20),

          // Scenarios
          _SectionHeader(title: 'Scenarios'),
          const SizedBox(height: 8),
          _ScenarioCard(
            icon: Icons.timer,
            title: 'Periodic Logger',
            subtitle: _periodicTimer != null
                ? 'Running ($_periodicCounter logs)'
                : 'Logs every second',
            trailing: Switch(
              value: _periodicTimer != null,
              onChanged: (_) => _togglePeriodicLogger(),
            ),
          ),
          const SizedBox(height: 8),
          _ScenarioCard(
            icon: Icons.navigation,
            title: 'Navigation Test',
            subtitle: 'Push a detail page',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToDetail(context),
          ),
          const SizedBox(height: 8),
          _ScenarioCard(
            icon: Icons.error_outline,
            title: 'Crash Simulation',
            subtitle: 'Unhandled exception via Zone',
            trailing: const Icon(Icons.chevron_right),
            onTap: _simulateCrash,
          ),
          const SizedBox(height: 8),
          _ScenarioCard(
            icon: Icons.data_object,
            title: 'Complex Payload',
            subtitle: 'Log deeply nested JSON',
            trailing: const Icon(Icons.chevron_right),
            onTap: _logComplexPayload,
          ),
          const SizedBox(height: 8),
          _ScenarioCard(
            icon: Icons.speed,
            title: 'Performance Jank',
            subtitle: 'Block UI thread ~250 ms — overlay spikes, '
                'performance-jank log entry appears in viewer',
            trailing: const Icon(Icons.chevron_right),
            onTap: _triggerSevereJank,
          ),
          const SizedBox(height: 20),

          // Riverpod
          _SectionHeader(title: 'Riverpod'),
          const SizedBox(height: 8),
          const _RiverpodScenarios(),
          const SizedBox(height: 20),

          // BLoC
          _SectionHeader(title: 'BLoC'),
          const SizedBox(height: 8),
          const _BlocScenarios(),
          const SizedBox(height: 20),

          // Network & DB
          _SectionHeader(title: 'Network & Database'),
          const SizedBox(height: 8),
          _NetworkDbSection(),
          const SizedBox(height: 20),

          // Domain traces
          _SectionHeader(title: 'Domain Traces'),
          const SizedBox(height: 8),
          _DomainTracesSection(),
          const SizedBox(height: 20),

          // Stress test
          _SectionHeader(title: 'Stress Test'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SliderControl(
                    label: 'Count',
                    value: _logCount,
                    min: 1,
                    max: 10000,
                    divisions: 99,
                    displayValue: _logCount.round().toString(),
                    onChanged: (v) => setState(() => _logCount = v),
                  ),
                  _SliderControl(
                    label: 'List size',
                    value: _listSize,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    displayValue: _listSize.round().toString(),
                    onChanged: (v) => setState(() => _listSize = v),
                  ),
                  _SliderControl(
                    label: 'Nesting',
                    value: _nestingDepth,
                    min: 0,
                    max: 6,
                    divisions: 6,
                    displayValue: _nestingDepth.round().toString(),
                    onChanged: (v) => setState(() => _nestingDepth = v),
                  ),
                  const SizedBox(height: 12),
                  if (_isGenerating)
                    const LinearProgressIndicator()
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final e in [
                          ('Info', Colors.blue, 'info'),
                          ('Debug', Colors.green, 'debug'),
                          ('Warning', Colors.orange, 'warning'),
                          ('Error', Colors.red, 'error'),
                          ('Mixed', Colors.purple, 'mixed'),
                        ])
                          FilledButton.tonal(
                            onPressed: () => _generateLogs(type: e.$3),
                            style: FilledButton.styleFrom(
                              foregroundColor: e.$2,
                            ),
                            child: Text(e.$1),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Actions --

  Future<void> _generateAllLogTypes() async {
    setState(() => _isGeneratingAllTypes = true);
    try {
      await _runAllLogTypes();
    } finally {
      setState(() => _isGeneratingAllTypes = false);
    }
  }

  Future<void> _runAllLogTypes() async {
    final logger = ISpect.logger;

    // ── General ──────────────────────────────────────────────────────────
    logger.info('Sample info message', additionalData: {'type': 'info'});
    logger.debug('Sample debug message', additionalData: {'type': 'debug'});
    logger.verbose('Sample verbose trace', additionalData: {'type': 'verbose'});
    logger
        .warning('Sample warning message', additionalData: {'type': 'warning'});
    logger.error(
      'Sample error message',
      exception: Exception('SampleError'),
      stackTrace: StackTrace.current,
    );
    logger.critical(
      'Sample critical message',
      exception: Exception('SampleCritical'),
      stackTrace: StackTrace.current,
    );
    logger.handle(
      exception: Exception('SampleException'),
      stackTrace: StackTrace.current,
      message: 'Sample exception (handle)',
    );
    logger.good('Sample good message');
    logger.print('Sample print message');
    logger.route('/home \u2192 /detail', transitionId: generateTraceId());
    logger.provider('Sample provider state updated');
    logger.track(
      'sample_event',
      event: 'sample_event',
      parameters: {'screen': 'AllLogTypes', 'source': 'manual'},
    );

    // \u2500\u2500 HTTP \u2014 correlationId links request \u2192 response \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    // Success: request + response share the same corrId
    final httpOkId = generateTraceId();
    logger.log(
      'GET https://api.example.com/users',
      type: ISpectLogType.httpRequest,
      additionalData: {
        TraceKeys.correlationId: httpOkId,
        'method': 'GET',
        'url': 'https://api.example.com/users',
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    logger.log(
      '200 OK \u2014 3 users returned',
      type: ISpectLogType.httpResponse,
      additionalData: {
        TraceKeys.correlationId: httpOkId,
        'status': 200,
        'durationMs': 80,
      },
    );
    // Error: request + error share the same corrId
    final httpErrId = generateTraceId();
    logger.log(
      'GET https://api.example.com/missing',
      type: ISpectLogType.httpRequest,
      additionalData: {
        TraceKeys.correlationId: httpErrId,
        'method': 'GET',
        'url': 'https://api.example.com/missing',
      },
    );
    logger.log(
      '404 Not Found',
      type: ISpectLogType.httpError,
      exception: Exception('404 Not Found'),
      stackTrace: StackTrace.current,
      additionalData: {TraceKeys.correlationId: httpErrId, 'status': 404},
    );

    // \u2500\u2500 WebSocket \u2014 real connection through WsDiagnostics \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    await _runWebSocketDemo(logger);

    // \u2500\u2500 BLoC \u2014 correlationId = bloc instance ID, links full lifecycle \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    final blocId = generateTraceId();
    logger.log('CounterBloc',
        type: ISpectLogType.blocCreate,
        additionalData: {TraceKeys.correlationId: blocId});
    logger.log('IncrementEvent',
        type: ISpectLogType.blocEvent,
        additionalData: {
          TraceKeys.correlationId: blocId,
          'event': 'IncrementEvent'
        });
    logger.log('CounterState(0) \u2192 CounterState(1)',
        type: ISpectLogType.blocTransition,
        additionalData: {TraceKeys.correlationId: blocId, 'from': 0, 'to': 1});
    logger.log('CounterState(1)',
        type: ISpectLogType.blocState,
        additionalData: {
          TraceKeys.correlationId: blocId,
          'state': 'CounterState(1)'
        });
    logger.log('CounterBloc stream done',
        type: ISpectLogType.blocDone,
        additionalData: {TraceKeys.correlationId: blocId});
    logger.log('CounterBloc closed',
        type: ISpectLogType.blocClose,
        additionalData: {TraceKeys.correlationId: blocId});
    logger.log('Unhandled event',
        type: ISpectLogType.blocError,
        exception: Exception('Bad state: stream already closed'),
        stackTrace: StackTrace.current,
        additionalData: {TraceKeys.correlationId: blocId});

    // \u2500\u2500 Riverpod \u2014 correlationId = provider instance ID \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    final rvpId = generateTraceId();
    logger.log('counterProvider',
        type: ISpectLogType.riverpodAdd,
        additionalData: {TraceKeys.correlationId: rvpId});
    logger.log('counterProvider: 0 \u2192 1',
        type: ISpectLogType.riverpodUpdate,
        additionalData: {TraceKeys.correlationId: rvpId, 'prev': 0, 'next': 1});
    logger.log('counterProvider disposed',
        type: ISpectLogType.riverpodDispose,
        additionalData: {TraceKeys.correlationId: rvpId});
    logger.log('counterProvider threw',
        type: ISpectLogType.riverpodFail,
        exception: Exception('ProviderException: circular dependency'),
        stackTrace: StackTrace.current,
        additionalData: {TraceKeys.correlationId: rvpId});

    // \u2500\u2500 State \u2014 traceSync auto-times, picks stateChange / stateError \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    logger.traceSync<String>(
      category: stateCategory,
      source: 'home-cubit',
      operation: 'emit',
      run: () => 'LoadedState',
      projectResult: (s) => {'state': s},
    );
    try {
      logger.traceSync<void>(
        category: stateCategory,
        source: 'home-cubit',
        operation: 'emit',
        config: const ISpectTraceConfig(attachStackOnError: true),
        run: () => throw Exception('StateError: unexpected transition'),
      );
    } catch (_) {}

    // \u2500\u2500 DB \u2014 dbTrace (query\u2192dbQuery), dbTrace (insert\u2192dbResult), slow query, \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    //         dbTrace error, dbTraceSync, dbStart/dbEnd, dbTransaction

    // 'query' op \u2192 dbQuery type
    await logger.dbTrace<List<Map<String, Object?>>>(
      source: 'sqlite',
      operation: 'query',
      table: 'users',
      statement: 'SELECT * FROM users WHERE active = ? LIMIT 10',
      args: [true],
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 12));
        return [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ];
      },
      projectResult: (rows) => {'rows': rows.length},
    );
    // 'insert' op \u2192 dbResult type
    await logger.dbTrace<int>(
      source: 'sqlite',
      operation: 'insert',
      table: 'events',
      statement: 'INSERT INTO events (type, ts) VALUES (?, ?)',
      args: ['page_view', DateTime.now().millisecondsSinceEpoch],
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 42;
      },
      projectResult: (id) => {'insertedId': id},
    );
    // Slow query: delay (300ms) > slowThreshold (250ms) \u2192 slow:true in log
    await logger.dbTrace<List<Map<String, Object?>>>(
      source: 'sqlite',
      operation: 'query',
      table: 'analytics',
      statement:
          'SELECT user_id, COUNT(*) FROM events GROUP BY user_id HAVING COUNT(*) > ?',
      args: [10],
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return [
          {'user_id': 1, 'count': 42},
        ];
      },
    );
    // DB error \u2192 dbError type
    try {
      await logger.dbTrace<void>(
        source: 'sqlite',
        operation: 'query',
        table: 'missing_table',
        statement: 'SELECT * FROM missing_table',
        run: () async =>
            throw Exception('DBError: no such table: missing_table'),
      );
    } catch (_) {}
    // Sync variant
    logger.dbTraceSync<String?>(
      source: 'hive',
      operation: 'get',
      key: 'session_token',
      run: () => 'eyJhbGciOiJSUzI1NiJ9...',
    );
    // Manual span: dbStart / dbEnd (when you control timing externally)
    final dbToken = logger.dbStart(
      source: 'sqlite',
      operation: 'update',
      table: 'accounts',
      statement: 'UPDATE accounts SET last_seen = ? WHERE id = ?',
      args: [DateTime.now().millisecondsSinceEpoch, 1],
    );
    await Future<void>.delayed(const Duration(milliseconds: 8));
    logger.dbEnd(dbToken, success: true, affected: 1);
    // Transaction: injects zone txnId into every nested dbTrace/db call
    await logger.dbTransaction(
      source: 'sqlite',
      logMarkers: true, // emits transaction-begin / commit / rollback logs
      run: () async {
        await logger.dbTrace<int>(
          source: 'sqlite',
          operation: 'update',
          table: 'accounts',
          statement: 'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          args: [50, 1],
          run: () async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return 1;
          },
        );
        await logger.dbTrace<int>(
          source: 'sqlite',
          operation: 'update',
          table: 'accounts',
          statement: 'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          args: [50, 2],
          run: () async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return 1;
          },
        );
      },
    );

    // \u2500\u2500 Auth \u2014 authTrace with projectResult, correlationId, ISpectTraceConfig \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    final authCorrId = generateTraceId();
    await logger.authTrace<Map<String, Object?>>(
      source: 'firebase_auth',
      operation: 'sign-in',
      provider: 'email',
      correlationId: authCorrId,
      config: const ISpectTraceConfig(
        attachStackOnError: true,
        slowThreshold: Duration(milliseconds: 200),
      ),
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return {'uid': 'usr_001', 'email': 'user@example.com'};
      },
      projectResult: (u) => {'uid': u['uid']},
    );
    // Token refresh (same corrId = same session), sampleRate: log ~50% of successes
    await logger.authTrace<String>(
      source: 'firebase_auth',
      operation: 'token-refresh',
      userId: 'usr_001',
      correlationId: authCorrId,
      config: const ISpectTraceConfig(
        sampleRate: 0.5,
        attachStackOnError: true,
      ),
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        return 'eyJhbGciOiJSUzI1NiJ9...';
      },
    );
    // Auth error
    try {
      await logger.authTrace<void>(
        source: 'firebase_auth',
        operation: 'sign-in',
        provider: 'google',
        correlationId: generateTraceId(),
        config: const ISpectTraceConfig(attachStackOnError: true),
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          throw Exception('auth/network-request-failed');
        },
      );
    } catch (_) {}

    // \u2500\u2500 Storage \u2014 'download'\u2192storageQuery, 'upload'\u2192storageResult \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    final storageCorrId = generateTraceId();
    // 'download' is in secondaryOperations \u2192 storageQuery type
    await logger.storageTrace<List<int>>(
      source: 'firebase_storage',
      operation: 'download',
      bucket: 'gs://my-app.appspot.com',
      path: '/documents/report.pdf',
      contentType: 'application/pdf',
      correlationId: storageCorrId,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return List.generate(1024, (i) => i % 256);
      },
      projectResult: (bytes) => {'sizeBytes': bytes.length},
    );
    // 'upload' not in secondaryOperations \u2192 storageResult type
    await logger.storageTrace<String>(
      source: 'firebase_storage',
      operation: 'upload',
      bucket: 'gs://my-app.appspot.com',
      path: '/avatars/usr_001/photo.jpg',
      sizeBytes: 245760,
      contentType: 'image/jpeg',
      correlationId: storageCorrId,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return 'https://storage.googleapis.com/my-app/photo.jpg';
      },
      projectResult: (url) => {'downloadUrl': url},
    );
    // Storage error
    try {
      await logger.storageTrace<void>(
        source: 'firebase_storage',
        operation: 'delete',
        path: '/temp/stale.bin',
        correlationId: generateTraceId(),
        config: const ISpectTraceConfig(attachStackOnError: true),
        run: () async => throw Exception('StorageError: object does not exist'),
      );
    } catch (_) {}

    // \u2500\u2500 Push \u2014 messageId auto-used as correlationId, links receive \u2192 open \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    const pushMsgId = 'msg_push_sample_001';
    logger.push(
      source: 'fcm',
      operation: 'received',
      title: 'New message from Alice',
      topic: 'chat',
      messageId: pushMsgId,
      data: {'chatId': 'chat_42', 'senderId': 'usr_alice'},
    );
    logger.push(
      source: 'fcm',
      operation: 'opened',
      messageId:
          pushMsgId, // same corrId via messageId \u2192 links to received
      data: {'action': 'open_chat', 'chatId': 'chat_42'},
    );
    // 'send' op \u2192 pushSent type (in secondaryOperations)
    logger.push(
      source: 'fcm',
      operation: 'send',
      topic: 'promotions',
      correlationId: generateTraceId(),
      meta: {'count': 1000, 'dryRun': false},
    );
    // pushError via logger.log (push() has no error param by design)
    logger.log(
      'FCM delivery failed: invalid token',
      type: ISpectLogType.pushError,
      exception: Exception('PushError: invalid-registration-token'),
      stackTrace: StackTrace.current,
      additionalData: {'source': 'fcm', 'operation': 'deliver'},
    );

    // \u2500\u2500 Analytics \u2014 correlationId links events of the same user session \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    final analyticsCorrId = generateTraceId();
    logger.analyticsEvent(
      source: 'firebase_analytics',
      event: 'screen_view',
      correlationId: analyticsCorrId,
      parameters: {
        'screen_name': 'AllLogTypes',
        'screen_class': '_HomePage',
      },
    );
    logger.analyticsEvent(
      source: 'firebase_analytics',
      event: 'button_tap',
      correlationId: analyticsCorrId,
      parameters: {'button': 'generate_all_logs'},
    );

    // \u2500\u2500 Payment \u2014 paymentTrace with projectResult, correlationId \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    final paymentCorrId = generateTraceId();
    await logger.paymentTrace<Map<String, Object?>>(
      source: 'stripe',
      operation: 'charge',
      productId: 'prod_premium_monthly',
      amount: 9.99,
      currency: 'USD',
      correlationId: paymentCorrId,
      meta: {'customerId': 'cus_abc123', 'paymentMethod': 'pm_card_visa'},
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return {'chargeId': 'ch_001', 'status': 'succeeded'};
      },
      projectResult: (r) => {'chargeId': r['chargeId'], 'status': r['status']},
    );
    // Same corrId = same checkout flow
    try {
      await logger.paymentTrace<void>(
        source: 'stripe',
        operation: 'charge',
        amount: 29.99,
        currency: 'USD',
        correlationId: paymentCorrId,
        config: const ISpectTraceConfig(attachStackOnError: true),
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          throw Exception('PaymentError: card_declined');
        },
      );
    } catch (_) {}

    // \u2500\u2500 SSE \u2014 correlationId links all events of the same stream session \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    final sseId = generateTraceId();
    logger.sse(
      source: 'event-stream',
      operation: 'event',
      url: 'https://api.example.com/stream',
      eventType: 'update',
      eventId: 'evt-001',
      correlationId: sseId,
      data: {'status': 'ok', 'ts': 1234567890},
    );
    logger.sse(
      source: 'event-stream',
      operation: 'event',
      url: 'https://api.example.com/stream',
      eventType: 'ping',
      eventId: 'evt-002',
      correlationId: sseId,
    );
    logger.sse(
      source: 'event-stream',
      operation: 'error',
      url: 'https://api.example.com/stream',
      correlationId: sseId,
      error: Exception('SSEError: connection timeout after 30s'),
      errorStackTrace: StackTrace.current,
    );

    // \u2500\u2500 gRPC \u2014 correlationId links request \u2192 response \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    final grpcCorrId = generateTraceId();
    await logger.grpcTrace<Map<String, Object?>>(
      source: 'grpc',
      operation: 'unary',
      service: 'UserService',
      method: 'GetProfile',
      correlationId: grpcCorrId,
      grpcMetadata: {
        'x-request-id': grpcCorrId,
        'authorization': 'Bearer eyJ...',
      },
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 45));
        return {'userId': 'usr_001', 'displayName': 'John Doe'};
      },
      projectResult: (p) => {'userId': p['userId']},
    );
    try {
      await logger.grpcTrace<void>(
        source: 'grpc',
        operation: 'unary',
        service: 'OrderService',
        method: 'PlaceOrder',
        correlationId: generateTraceId(),
        config: const ISpectTraceConfig(attachStackOnError: true),
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          throw Exception('gRPC status: UNAVAILABLE');
        },
      );
    } catch (_) {}

    // \u2500\u2500 GraphQL \u2014 correlationId links query \u2192 response \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    final gqlCorrId = generateTraceId();
    await logger.graphqlTrace<Map<String, Object?>>(
      source: 'graphql',
      operation: 'query',
      operationName: 'GetUser',
      document: r'query GetUser($id: ID!) { user(id: $id) { id name email } }',
      variables: {'id': 'usr_001'},
      correlationId: gqlCorrId,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        return {
          'user': {
            'id': 'usr_001',
            'name': 'Alice',
            'email': 'alice@example.com',
          },
        };
      },
      projectResult: (r) => {'userId': (r['user']! as Map)['id']},
    );
    try {
      await logger.graphqlTrace<void>(
        source: 'graphql',
        operation: 'mutation',
        operationName: 'DeletePost',
        document: r'mutation DeletePost($id: ID!) { deletePost(id: $id) }',
        variables: {'id': 'post_999'},
        correlationId: generateTraceId(),
        config: const ISpectTraceConfig(attachStackOnError: true),
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          throw Exception('GraphQL: Not authorized');
        },
      );
    } catch (_) {}

    // \u2500\u2500 traceStart / traceEnd \u2014 manual span when auto-timing isn't available \u2500\u2500\u2500\u2500\u2500\u2500
    final networkToken = logger.traceStart(
      category: networkCategory,
      source: 'custom-client',
      operation: 'fetch',
      target: 'https://api.example.com/config',
      correlationId: generateTraceId(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 55));
    logger.traceEnd(networkToken, value: {'config': 'loaded'}, success: true);
    // traceEnd with error
    final authToken = logger.traceStart(
      category: authCategory,
      source: 'oauth',
      operation: 'exchange-code',
      correlationId: generateTraceId(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    logger.traceEnd(
      authToken,
      success: false,
      error: Exception('OAuth: invalid_grant'),
      errorStackTrace: StackTrace.current,
    );

    // \u2500\u2500 traceStream \u2014 auto logs subscribe / event / error / unsubscribe \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    await logger
        .traceStream<int>(
          category: dbCategory,
          source: 'sqlite',
          operation: 'watch-users',
          stream: Stream.fromIterable([1, 2, 3]),
          projectEvent: (row) => {'row': row},
        )
        .drain<void>();
  }

  void _togglePeriodicLogger() {
    setState(() {
      if (_periodicTimer != null) {
        _periodicTimer!.cancel();
        _periodicTimer = null;
        ISpect.logger.info(
          'Periodic logger stopped after $_periodicCounter logs',
        );
        _periodicCounter = 0;
      } else {
        _periodicCounter = 0;
        _periodicTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _periodicCounter++;
          final types = ['info', 'debug', 'warning', 'verbose', 'good'];
          final type = types[_periodicCounter % types.length];
          switch (type) {
            case 'info':
              ISpect.logger.info('Periodic #$_periodicCounter');
            case 'debug':
              ISpect.logger.debug('Periodic #$_periodicCounter: state OK');
            case 'warning':
              ISpect.logger.warning(
                'Periodic #$_periodicCounter: memory usage high',
              );
            case 'verbose':
              ISpect.logger.verbose('Periodic #$_periodicCounter: tick');
            case 'good':
              ISpect.logger.good('Periodic #$_periodicCounter: healthy');
          }
          setState(() {});
        });
        ISpect.logger.info('Periodic logger started');
      }
    });
  }

  void _navigateToDetail(BuildContext context) {
    ISpect.logger.info('Navigating to detail page');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/detail'),
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Detail Page')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This tests navigation observer logging.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    ISpect.logger.info('Going back from detail');
                    Navigator.of(context).pop();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _simulateCrash() {
    ISpect.logger.warning('About to simulate crash...');
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      throw StateError('Simulated crash for ISpect testing');
    });
  }

  void _triggerSevereJank() {
    // Run heavy work after the current frame so the tap response paints
    // before the freeze — otherwise the snackbar would also be stuck.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final sw = Stopwatch()..start();
      var acc = 0.0;
      while (sw.elapsedMilliseconds < 250) {
        for (var i = 0; i < 20000; i++) {
          acc += i * 1.000001;
        }
      }
      // Touch `acc` so the loop is not optimized away in release builds.
      if (acc < 0) ISpect.logger.debug('unreachable $acc');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Blocking UI thread ~250 ms — watch the overlay'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _logComplexPayload() {
    ISpect.logger.info(
      'Complex payload with deep nesting',
      additionalData: {
        'user': {
          'id': 42,
          'name': 'John Doe',
          'roles': ['admin', 'editor'],
          'preferences': {
            'theme': 'dark',
            'notifications': {
              'email': true,
              'push': false,
              'sms': {'enabled': true, 'number': '+1234567890'},
            },
          },
        },
        'items': List.generate(
          10,
          (i) => {
            'id': i,
            'title': 'Item #$i',
            'tags': List.generate(3, (j) => 'tag_${i}_$j'),
            'metadata': {
              'created':
                  DateTime.now().subtract(Duration(hours: i)).toIso8601String(),
              'weight': (i * 1.5).toStringAsFixed(2),
            },
          },
        ),
        'pagination': {
          'page': 1,
          'perPage': 10,
          'total': 156,
          'hasNext': true,
        },
      },
    );
  }

  Future<void> _generateLogs({required String type}) async {
    setState(() => _isGenerating = true);
    final count = _logCount.round();
    final listSize = _listSize.round();
    final nestingDepth = _nestingDepth.round();
    final data = _buildList(listSize, nestingDepth);
    final nested = _buildNestedMap(nestingDepth, listSize.clamp(1, 5));

    for (var i = 0; i < count; i++) {
      final n = i + 1;
      switch (type) {
        case 'info':
          ISpect.logger.info('Info #$n', additionalData: {'items': data});
        case 'debug':
          ISpect.logger.debug('Debug #$n', additionalData: {'nested': nested});
        case 'warning':
          ISpect.logger.warning('Warning #$n', additionalData: {'rows': data});
        case 'error':
          ISpect.logger.error(
            'Error #$n',
            exception: Exception('BatchError #$n'),
            stackTrace: StackTrace.current,
            additionalData: {'input': data},
          );
        case 'mixed':
          final types = ['info', 'debug', 'warning', 'error', 'verbose'];
          final t = types[i % types.length];
          switch (t) {
            case 'info':
              ISpect.logger
                  .info('Mixed #$n [INFO]', additionalData: {'d': data});
            case 'debug':
              ISpect.logger
                  .debug('Mixed #$n [DEBUG]', additionalData: {'d': nested});
            case 'warning':
              ISpect.logger
                  .warning('Mixed #$n [WARN]', additionalData: {'d': data});
            case 'error':
              ISpect.logger.error(
                'Mixed #$n [ERROR]',
                exception: Exception('MixedError #$n'),
                stackTrace: StackTrace.current,
              );
            case 'verbose':
              ISpect.logger.verbose('Mixed #$n [VERBOSE]',
                  additionalData: {'d': nested});
          }
      }
      if (i % 100 == 99) await Future<void>.delayed(Duration.zero);
    }
    setState(() => _isGenerating = false);
  }

  // -- Data builders --

  Map<String, dynamic> _buildNestedMap(int depth, int breadth) {
    if (depth <= 0) {
      return {
        'value': 'leaf',
        'ts': DateTime.now().toIso8601String(),
        'tags': List.generate(breadth, (i) => 'tag_$i'),
      };
    }
    return {
      'level': depth,
      'items': List.generate(
        breadth,
        (i) => {'item_$i': _buildNestedMap(depth - 1, breadth.clamp(1, 3))},
      ),
    };
  }

  List<Map<String, dynamic>> _buildList(int size, int nestingDepth) {
    return List.generate(
        size,
        (i) => {
              'index': i,
              'id': 'item_${i.toString().padLeft(4, '0')}',
              'name': 'Element #$i',
              'active': i.isEven,
              if (nestingDepth > 0)
                'nested':
                    _buildNestedMap(nestingDepth, (size ~/ 3).clamp(1, 3)),
            });
  }
}

// ---------------------------------------------------------------------------
// Quick log buttons grid
// ---------------------------------------------------------------------------

/// Connects to a public echo server through the local `ws` adapter so the
/// WebSocket logs (`ws-sent` / `ws-received` / `ws-state`) are real, not
/// simulated. Bounded by a timeout so the demo never hangs offline.
Future<void> _runWebSocketDemo(ISpectLogger logger) async {
  const url = 'wss://echo.websocket.org';
  final interceptor = ISpectWSInterceptor(logger: logger);
  final client = WebSocketClient(
    WebSocketOptions.common(interceptors: [interceptor]),
  );
  interceptor.setClient(client);
  try {
    await client.connect(url).timeout(const Duration(seconds: 5));
    await client.add('{"type":"subscribe","channel":"prices"}');
    await Future<void>.delayed(const Duration(seconds: 1));
  } on Object catch (e, st) {
    logger.handle(
      exception: e,
      stackTrace: st,
      message: 'WebSocket demo failed',
    );
  } finally {
    await client.close();
    await interceptor.dispose();
  }
}

class _QuickLogsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logs = <(String, IconData, Color, VoidCallback)>[
      (
        'Info',
        Icons.info_outline,
        Colors.blue,
        () => ISpect.logger.info('Info message')
      ),
      (
        'Debug',
        Icons.bug_report_outlined,
        Colors.green,
        () => ISpect.logger.debug('Debug message')
      ),
      (
        'Warning',
        Icons.warning_amber,
        Colors.orange,
        () => ISpect.logger.warning('Warning message')
      ),
      (
        'Error',
        Icons.error_outline,
        Colors.red,
        () => ISpect.logger.error('Error message')
      ),
      (
        'Exception',
        Icons.dangerous_outlined,
        Colors.red.shade800,
        () => ISpect.logger.handle(
              exception: Exception('Test exception'),
              stackTrace: StackTrace.current,
            )
      ),
      (
        'Critical',
        Icons.local_fire_department,
        Colors.deepOrange,
        () => ISpect.logger.critical(
              'Critical failure',
              exception: Exception('CriticalTest'),
              stackTrace: StackTrace.current,
            )
      ),
      (
        'Good',
        Icons.check_circle_outline,
        Colors.teal,
        () => ISpect.logger.good('All systems operational')
      ),
      (
        'Verbose',
        Icons.text_snippet_outlined,
        Colors.grey,
        () => ISpect.logger.verbose('Verbose trace')
      ),
      (
        'Print',
        Icons.terminal,
        Colors.blueGrey,
        () => ISpect.logger.print('Print log')
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, icon, color, onTap) in logs)
          ActionChip(
            avatar: Icon(icon, size: 18, color: color),
            label: Text(label),
            onPressed: onTap,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scenario card
// ---------------------------------------------------------------------------

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod scenarios — real providers wired through ISpectRiverpodObserver
// ---------------------------------------------------------------------------

class _RiverpodScenarios extends ConsumerStatefulWidget {
  const _RiverpodScenarios();

  @override
  ConsumerState<_RiverpodScenarios> createState() => _RiverpodScenariosState();
}

class _RiverpodScenariosState extends ConsumerState<_RiverpodScenarios> {
  int _familyUserId = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counter = ref.watch(_counterProvider);
    final userName = ref.watch(_userNameProvider(_familyUserId));
    final flaky = ref.watch(_flakyFutureProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'counter: $counter   ·   ${_familyUserId == 0 ? 'no user' : userName}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'flaky-future: ${flaky.when(
                data: (v) => v,
                loading: () => 'loading…',
                error: (e, _) => 'error: $e',
              )}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('Increment'),
                  onPressed: () => ref.read(_counterProvider.notifier).state++,
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Invalidate counter'),
                  onPressed: () => ref.invalidate(_counterProvider),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.person_add),
                  label: Text('user-${_familyUserId + 1}'),
                  onPressed: () => setState(() => _familyUserId += 1),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.replay),
                  label: const Text('Retry flaky future'),
                  onPressed: () => ref.invalidate(_flakyFutureProvider),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Read failing provider'),
                  style: FilledButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    try {
                      ref.read(_failingProvider);
                    } on StateError catch (_) {
                      // Swallow — `providerDidFail` already routed it to ISpect.
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BLoC scenarios — real CounterBloc wired through ISpectBlocObserver
// ---------------------------------------------------------------------------

class _BlocScenarios extends StatefulWidget {
  const _BlocScenarios();

  @override
  State<_BlocScenarios> createState() => _BlocScenariosState();
}

class _BlocScenariosState extends State<_BlocScenarios> {
  // Bumping the key disposes the old bloc and creates a new one, exercising
  // onClose + onCreate in a single tap.
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocProvider<CounterBloc>(
              key: ValueKey(_generation),
              create: (_) => CounterBloc(),
              child: const _CounterView(),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.restart_alt),
              label: Text('Recreate bloc (gen #$_generation)'),
              onPressed: () => setState(() => _generation += 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterView extends StatelessWidget {
  const _CounterView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<CounterBloc, int>(
          builder: (context, count) => Text(
            'counter: $count',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add),
              label: const Text('Increment'),
              onPressed: () =>
                  context.read<CounterBloc>().add(const CounterIncremented()),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.remove),
              label: const Text('Decrement'),
              onPressed: () =>
                  context.read<CounterBloc>().add(const CounterDecremented()),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              onPressed: () =>
                  context.read<CounterBloc>().add(const CounterReset()),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.error_outline),
              label: const Text('Trigger error'),
              style: FilledButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () =>
                  context.read<CounterBloc>().add(const CounterFailed()),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Network & Database section
// ---------------------------------------------------------------------------

class _NetworkDbSection extends StatefulWidget {
  @override
  State<_NetworkDbSection> createState() => _NetworkDbSectionState();
}

class _NetworkDbSectionState extends State<_NetworkDbSection> {
  late final Dio _dio;
  late final InterceptedClient _httpClient;
  bool _isLoading = false;
  String? _accessToken;
  String? _refreshToken;

  final _dbConfig = const ISpectDbConfig(
    sampleRate: 1.0,
    redact: true,
    attachStackOnError: true,
    enableTransactionMarkers: true,
    slowThreshold: Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    final logger = ISpect.logger;

    _dio = Dio();
    _dio.interceptors.add(
      ISpectDioInterceptor(
        logger: logger,
        settings: const ISpectDioInterceptorSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printRequestData: true,
          printResponseData: true,
          enableRedaction: true,
        ),
      ),
    );

    _httpClient = InterceptedClient.build(
      interceptors: [
        ISpectHttpInterceptor(
          logger: logger,
          settings: ISpectHttpInterceptorSettingsBuilder()
              .withAllHeaders()
              .withRedaction()
              .build(),
        ),
      ],
    );

    // Expose both clients to the in-app HTTP composer ("mini-Postman"). Replays
    // and composed requests then travel through these same instrumented clients.
    ISpect.registerSender(DioRequestSender(_dio, label: 'Dio'));
    ISpect.registerSender(HttpClientRequestSender(_httpClient, label: 'HTTP'));
  }

  @override
  void dispose() {
    ISpect.unregisterSender('dio');
    ISpect.unregisterSender('http');
    _dio.close();
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_isLoading) const SizedBox(height: 12),

            Text(
              'HTTP composer: open the panel → api icon to compose a request, '
              'or fire any call below then long-press its network log → '
              'Edit & resend.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            // Dio
            Text(
              'Dio HTTP',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('GET todo', Icons.download, Colors.blue, () {
                  _dio.get('https://dummyjson.com/todos/1');
                }),
                _chip('GET products', Icons.list, Colors.blue, () {
                  _dio.get('https://dummyjson.com/products?limit=5');
                }),
                _chip('POST product', Icons.upload, Colors.green, () {
                  _dio.post(
                    'https://dummyjson.com/products/add',
                    data: {
                      'title': 'ISpect Test Product',
                      'description': 'Testing Dio interceptor',
                      'price': 99,
                    },
                  );
                }),
                _chip('PUT product', Icons.edit, Colors.orange, () {
                  _dio.put(
                    'https://dummyjson.com/products/1',
                    data: {'title': 'Updated Title'},
                  );
                }),
                _chip('DELETE product', Icons.delete, Colors.red, () {
                  _dio.delete('https://dummyjson.com/products/1');
                }),
                _chip('GET 404', Icons.error, Colors.red.shade800, () {
                  _dio.get('https://dummyjson.com/products/0');
                }),
                _chip('Invalid URL', Icons.link_off, Colors.grey, () {
                  _dio.get('htt://invalid-url');
                }),
              ],
            ),
            const SizedBox(height: 16),

            // HTTP package
            Text(
              'HTTP Package',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('GET users', Icons.people, Colors.blue, () {
                  _httpClient.get(
                    Uri.parse('https://dummyjson.com/users?limit=3'),
                  );
                }),
                _chip('GET recipes', Icons.restaurant, Colors.teal, () {
                  _httpClient.get(
                    Uri.parse('https://dummyjson.com/recipes?limit=5'),
                  );
                }),
                _chip('POST login', Icons.login, Colors.green, () {
                  _httpClient.post(
                    Uri.parse('https://dummyjson.com/auth/login'),
                    body: '{"username":"emilys","password":"emilyspass"}',
                    headers: {'Content-Type': 'application/json'},
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Redaction examples
            Text(
              'Redaction (Auth & Sensitive Data)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _accessToken != null
                  ? 'Logged in (token cached)'
                  : 'Tap "Login" first to get real tokens',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _accessToken != null ? Colors.green : Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Step 1: Login to get real tokens
                _chip(
                  'Login (get tokens)',
                  Icons.login,
                  Colors.deepPurple,
                  () async {
                    try {
                      final response = await _dio.post(
                        'https://dummyjson.com/auth/login',
                        data: {
                          'username': 'emilys',
                          'password': 'emilyspass',
                        },
                      );
                      final data = response.data as Map<String, dynamic>;
                      setState(() {
                        _accessToken = data['accessToken'] as String?;
                        _refreshToken = data['refreshToken'] as String?;
                      });
                    } catch (e, st) {
                      ISpect.logger.handle(exception: e, stackTrace: st);
                    }
                  },
                ),
                // Step 2: Use real access token
                _chip(
                  'GET /auth/me',
                  Icons.person,
                  Colors.deepPurple.shade300,
                  () {
                    _dio.get(
                      'https://dummyjson.com/auth/me',
                      options: Options(
                        headers: {
                          'Authorization':
                              'Bearer ${_accessToken ?? 'NO_TOKEN'}',
                        },
                      ),
                    );
                  },
                ),
                // Step 3: Refresh token flow
                _chip(
                  'Refresh token',
                  Icons.refresh,
                  Colors.deepPurple.shade200,
                  () async {
                    try {
                      final response = await _dio.post(
                        'https://dummyjson.com/auth/refresh',
                        data: {
                          'refreshToken': _refreshToken ?? 'NO_TOKEN',
                        },
                      );
                      final data = response.data as Map<String, dynamic>;
                      setState(() {
                        _accessToken = data['accessToken'] as String?;
                        _refreshToken = data['refreshToken'] as String?;
                      });
                    } catch (e, st) {
                      ISpect.logger.handle(exception: e, stackTrace: st);
                    }
                  },
                ),
                // API key + client secret headers
                _chip(
                  'API Key header',
                  Icons.vpn_key,
                  Colors.indigo,
                  () {
                    _dio.get(
                      'https://dummyjson.com/products/1',
                      options: Options(
                        headers: {
                          'Authorization':
                              'Bearer ${_accessToken ?? 'NO_TOKEN'}',
                          'X-Api-Key': 'sk-proj-abc123def456ghi789',
                          'X-Client-Secret': 'cs_live_xR7kL9mP2qW5nV8',
                        },
                      ),
                    );
                  },
                ),
                // Cookie header
                _chip(
                  'Cookie header',
                  Icons.cookie,
                  Colors.brown,
                  () {
                    _dio.get(
                      'https://dummyjson.com/users/1',
                      options: Options(
                        headers: {
                          'Cookie': 'session=abc123xyz; '
                              'accessToken=${_accessToken ?? 'NO_TOKEN'}',
                        },
                      ),
                    );
                  },
                ),
                // Sensitive body (PII, financial)
                _chip(
                  'Sensitive body',
                  Icons.security,
                  Colors.red.shade700,
                  () {
                    _dio.post(
                      'https://dummyjson.com/users/add',
                      data: {
                        'firstName': 'John',
                        'lastName': 'Doe',
                        'email': 'john@example.com',
                        'phone': '+1-555-0123',
                        'password': 'SuperSecret123!',
                        'ssn': '123-45-6789',
                        'credit_card': '4111111111111111',
                        'cvv': '123',
                        'bank_account': '9876543210',
                      },
                      options: Options(
                        headers: {
                          'Authorization':
                              'Bearer ${_accessToken ?? 'NO_TOKEN'}',
                        },
                      ),
                    );
                  },
                ),
                // Nested secrets in body
                _chip(
                  'Nested secrets',
                  Icons.account_tree,
                  Colors.teal.shade700,
                  () {
                    _dio.post(
                      'https://dummyjson.com/products/add',
                      data: {
                        'title': 'Test',
                        'metadata': {
                          'api_key': 'ak_test_51234567890',
                          'private_key': '-----BEGIN RSA PRIVATE KEY-----',
                          'config': {
                            'client_secret': 'whsec_abcdef123456',
                            'access_token': _accessToken ?? 'NO_TOKEN',
                            'refresh_token': _refreshToken ?? 'NO_TOKEN',
                          },
                        },
                      },
                    );
                  },
                ),
                // Query params with secrets
                _chip(
                  'Query params',
                  Icons.link,
                  Colors.indigo.shade400,
                  () {
                    _dio.get(
                      'https://dummyjson.com/products/search'
                      '?q=phone'
                      '&api_key=sk-12345'
                      '&token=${_accessToken ?? 'NO_TOKEN'}',
                    );
                  },
                ),
                // HTTP package with real token
                _chip(
                  'HTTP + auth',
                  Icons.http,
                  Colors.deepPurple.shade400,
                  () {
                    _httpClient.get(
                      Uri.parse('https://dummyjson.com/auth/me'),
                      headers: {
                        'Authorization': 'Bearer ${_accessToken ?? 'NO_TOKEN'}',
                        'X-Api-Key': 'sk-proj-abc123def456',
                      },
                    );
                  },
                ),
                // HTTP package login with creds
                _chip(
                  'HTTP + creds body',
                  Icons.password,
                  Colors.red.shade400,
                  () {
                    _httpClient.post(
                      Uri.parse('https://dummyjson.com/auth/login'),
                      body: '{'
                          '"username":"emilys",'
                          '"password":"emilyspass",'
                          '"expiresInMins":1'
                          '}',
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Basic dXNlcjpwYXNzd29yZA==',
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Database
            Text(
              'Database Queries',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('SELECT users', Icons.storage, Colors.indigo, () {
                  _runDbExample();
                }),
                _chip('INSERT user', Icons.person_add, Colors.green, () {
                  _runDbInsert();
                }),
                _chip('UPDATE user', Icons.edit_note, Colors.orange, () {
                  _runDbUpdate();
                }),
                _chip('DELETE user', Icons.person_remove, Colors.red, () {
                  _runDbDelete();
                }),
                _chip('Transaction', Icons.swap_horiz, Colors.purple, () {
                  _runDbTransaction();
                }),
                _chip('KV get', Icons.key, Colors.brown, () {
                  _runDbKeyValue();
                }),
                _chip('Slow query', Icons.hourglass_bottom, Colors.amber, () {
                  _runDbSlowQuery();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: () {
        setState(() => _isLoading = true);
        onTap();
        Future<void>.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _isLoading = false);
        });
      },
    );
  }

  // -- DB examples --

  Future<void> _runDbExample() async {
    await ISpect.logger.dbTrace<List<Map<String, Object?>>>(
      source: 'drift',
      operation: 'query',
      table: 'users',
      statement: 'SELECT * FROM users WHERE active = ? ORDER BY name LIMIT 10',
      args: [true],
      config: _dbConfig,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 15));
        return [
          {'id': 1, 'name': 'Alice', 'active': true},
          {'id': 2, 'name': 'Bob', 'active': true},
          {'id': 3, 'name': 'Charlie', 'active': true},
        ];
      },
      projectResult: (rows) => {'rows': rows.length},
    );
  }

  Future<void> _runDbInsert() async {
    await ISpect.logger.dbTrace<int>(
      source: 'drift',
      operation: 'insert',
      table: 'users',
      statement: "INSERT INTO users (name, email, active) VALUES (?, ?, ?)",
      args: ['Dave', 'dave@example.com', true],
      config: _dbConfig,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 8));
        return 4;
      },
      projectResult: (id) => {'insertedId': id},
    );
  }

  Future<void> _runDbUpdate() async {
    await ISpect.logger.dbTrace<int>(
      source: 'drift',
      operation: 'update',
      table: 'users',
      statement: 'UPDATE users SET name = ?, email = ? WHERE id = ?',
      args: ['Dave Updated', 'dave_new@example.com', 4],
      config: _dbConfig,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 1;
      },
      projectResult: (affected) => {'affectedRows': affected},
    );
  }

  Future<void> _runDbDelete() async {
    await ISpect.logger.dbTrace<int>(
      source: 'drift',
      operation: 'delete',
      table: 'users',
      statement: 'DELETE FROM users WHERE id = ?',
      args: [4],
      config: _dbConfig,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 1;
      },
      projectResult: (affected) => {'deletedRows': affected},
    );
  }

  Future<void> _runDbTransaction() async {
    await ISpect.logger.dbTransaction(
      source: 'drift',
      logMarkers: true,
      config: _dbConfig,
      run: () async {
        await ISpect.logger.dbTrace<int>(
          source: 'drift',
          operation: 'update',
          table: 'accounts',
          statement: 'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          args: [100, 1],
          config: _dbConfig,
          run: () async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return 1;
          },
        );
        await ISpect.logger.dbTrace<int>(
          source: 'drift',
          operation: 'update',
          table: 'accounts',
          statement: 'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          args: [100, 2],
          config: _dbConfig,
          run: () async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return 1;
          },
        );
      },
    );
  }

  Future<void> _runDbKeyValue() async {
    await ISpect.logger.dbTrace<String?>(
      source: 'hive',
      operation: 'get',
      key: 'session_token',
      config: _dbConfig,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 3));
        return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
      },
    );

    await ISpect.logger.dbTrace<bool>(
      source: 'shared_prefs',
      operation: 'write',
      key: 'onboarding_done',
      config: _dbConfig,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 2));
        return true;
      },
    );
  }

  Future<void> _runDbSlowQuery() async {
    await ISpect.logger.dbTrace<List<Map<String, Object?>>>(
      source: 'drift',
      operation: 'query',
      table: 'analytics',
      statement:
          'SELECT user_id, COUNT(*) as cnt, AVG(duration) as avg_dur FROM analytics GROUP BY user_id HAVING cnt > ? ORDER BY avg_dur DESC',
      args: [10],
      config: _dbConfig,
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return [
          {'user_id': 1, 'cnt': 42, 'avg_dur': 1250.5},
          {'user_id': 7, 'cnt': 28, 'avg_dur': 980.3},
        ];
      },
      projectResult: (rows) => {'rows': rows.length},
    );
  }
}

// ---------------------------------------------------------------------------
// Domain traces section
// ---------------------------------------------------------------------------

class _DomainTracesSection extends StatefulWidget {
  @override
  State<_DomainTracesSection> createState() => _DomainTracesSectionState();
}

class _DomainTracesSectionState extends State<_DomainTracesSection> {
  bool _isLoading = false;

  Widget _chip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: () {
        setState(() => _isLoading = true);
        onTap();
        Future<void>.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _isLoading = false);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_isLoading) const SizedBox(height: 12),

            // Auth
            Text('Auth', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Sign in', Icons.login, Colors.green, _authSignIn),
                _chip('Sign up', Icons.person_add, Colors.blue, _authSignUp),
                _chip('Token refresh', Icons.refresh, Colors.orange,
                    _authRefresh),
                _chip('Sign out', Icons.logout, Colors.red, _authSignOut),
                _chip('Sign in (fail)', Icons.error, Colors.red.shade800,
                    _authFail),
              ],
            ),
            const SizedBox(height: 16),

            // Storage
            Text('Storage', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Upload file', Icons.cloud_upload, Colors.blue,
                    _storageUpload),
                _chip('Download file', Icons.cloud_download, Colors.green,
                    _storageDownload),
                _chip('Delete file', Icons.delete_forever, Colors.red,
                    _storageDelete),
              ],
            ),
            const SizedBox(height: 16),

            // Push
            Text(
              'Push Notifications',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                    'Received', Icons.notifications, Colors.blue, _pushReceive),
                _chip('Opened', Icons.touch_app, Colors.green, _pushOpened),
                _chip('Subscribe', Icons.subscriptions, Colors.purple,
                    _pushSubscribe),
              ],
            ),
            const SizedBox(height: 16),

            // Analytics
            Text('Analytics', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Screen view', Icons.visibility, Colors.blue,
                    _analyticsScreen),
                _chip('Button tap', Icons.touch_app, Colors.green,
                    _analyticsButton),
                _chip('Purchase', Icons.shopping_cart, Colors.orange,
                    _analyticsPurchase),
              ],
            ),
            const SizedBox(height: 16),

            // Payment
            Text('Payment', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                    'Purchase', Icons.payment, Colors.green, _paymentPurchase),
                _chip('Refund', Icons.money_off, Colors.red, _paymentRefund),
                _chip('Subscription', Icons.card_membership, Colors.purple,
                    _paymentSubscription),
              ],
            ),
            const SizedBox(height: 16),

            // gRPC
            Text('gRPC', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Unary call', Icons.call_made, Colors.blue, _grpcUnary),
                _chip('Server stream', Icons.stream, Colors.teal,
                    _grpcServerStream),
                _chip('Error call', Icons.error, Colors.red, _grpcError),
              ],
            ),
            const SizedBox(height: 16),

            // GraphQL
            Text('GraphQL', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Query', Icons.search, Colors.blue, _graphqlQuery),
                _chip('Mutation', Icons.edit, Colors.orange, _graphqlMutation),
              ],
            ),
            const SizedBox(height: 16),

            // SSE
            Text('SSE (Server-Sent Events)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Connect', Icons.link, Colors.blue, _sseConnect),
                _chip('Events', Icons.bolt, Colors.green, _sseEvents),
                _chip('Error', Icons.error, Colors.red, _sseError),
              ],
            ),
            const SizedBox(height: 16),

            // WebSocket
            Text('WebSocket', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Connect & subscribe', Icons.cable, Colors.teal,
                    _wsSubscribe),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── WebSocket ───────────────────────────────────────────────────────────

  Future<void> _wsSubscribe() => _runWebSocketDemo(ISpect.logger);

  // ── Auth ──────────────────────────────────────────────────────────────

  Future<void> _authSignIn() async {
    await ISpect.logger.authTrace<Map<String, Object?>>(
      source: 'firebase_auth',
      operation: 'sign-in',
      provider: 'email',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return {'uid': 'usr_abc123', 'email': 'user@example.com'};
      },
      projectResult: (user) => {'uid': user['uid']},
    );
  }

  Future<void> _authSignUp() async {
    await ISpect.logger.authTrace<Map<String, Object?>>(
      source: 'firebase_auth',
      operation: 'sign-up',
      provider: 'email',
      meta: {'plan': 'premium'},
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return {'uid': 'usr_new456', 'email': 'new@example.com'};
      },
      projectResult: (user) => {'uid': user['uid']},
    );
  }

  Future<void> _authRefresh() async {
    await ISpect.logger.authTrace<String>(
      source: 'firebase_auth',
      operation: 'token-refresh',
      userId: 'usr_abc123',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...';
      },
    );
  }

  void _authSignOut() {
    ISpect.logger.auth(
      source: 'firebase_auth',
      operation: 'sign-out',
      userId: 'usr_abc123',
      success: true,
    );
  }

  Future<void> _authFail() async {
    try {
      await ISpect.logger.authTrace<void>(
        source: 'firebase_auth',
        operation: 'sign-in',
        provider: 'google',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          throw Exception('auth/network-request-failed');
        },
      );
    } catch (_) {}
  }

  // ── Storage ──────────────────────────────────────────────────────────

  Future<void> _storageUpload() async {
    await ISpect.logger.storageTrace<String>(
      source: 'firebase_storage',
      operation: 'upload',
      bucket: 'gs://my-app.appspot.com',
      path: '/avatars/usr_abc123/photo.jpg',
      sizeBytes: 245760,
      contentType: 'image/jpeg',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return 'https://storage.googleapis.com/my-app/avatars/photo.jpg';
      },
      projectResult: (url) => {'downloadUrl': url},
    );
  }

  Future<void> _storageDownload() async {
    await ISpect.logger.storageTrace<List<int>>(
      source: 'firebase_storage',
      operation: 'download',
      bucket: 'gs://my-app.appspot.com',
      path: '/documents/report_2024.pdf',
      contentType: 'application/pdf',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        return List.generate(1024, (i) => i % 256);
      },
      projectResult: (bytes) => {'sizeBytes': bytes.length},
    );
  }

  Future<void> _storageDelete() async {
    await ISpect.logger.storageTrace<void>(
      source: 'firebase_storage',
      operation: 'delete',
      bucket: 'gs://my-app.appspot.com',
      path: '/temp/cache_old.bin',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
    );
  }

  // ── Push ──────────────────────────────────────────────────────────────

  void _pushReceive() {
    ISpect.logger.push(
      source: 'fcm',
      operation: 'received',
      title: 'New message from Alice',
      topic: 'chat',
      messageId: 'msg_push_001',
      data: {
        'chatId': 'chat_42',
        'senderId': 'usr_alice',
        'body': 'Hey, check out this feature!',
      },
    );
  }

  void _pushOpened() {
    ISpect.logger.push(
      source: 'fcm',
      operation: 'opened',
      title: 'New message from Alice',
      messageId: 'msg_push_001',
      data: {'chatId': 'chat_42', 'action': 'open_chat'},
    );
  }

  void _pushSubscribe() {
    ISpect.logger.push(
      source: 'fcm',
      operation: 'subscribe',
      topic: 'promotions',
      meta: {
        'previousTopics': ['news', 'updates']
      },
    );
  }

  // ── Analytics ─────────────────────────────────────────────────────────

  void _analyticsScreen() {
    ISpect.logger.analyticsEvent(
      source: 'firebase_analytics',
      event: 'screen_view',
      parameters: {
        'screen_name': 'ProductDetail',
        'screen_class': 'ProductDetailScreen',
        'product_id': 'prod_789',
      },
    );
  }

  void _analyticsButton() {
    ISpect.logger.analyticsEvent(
      source: 'firebase_analytics',
      event: 'button_click',
      parameters: {
        'button_id': 'add_to_cart',
        'screen': 'ProductDetail',
        'product_id': 'prod_789',
        'product_price': 29.99,
      },
    );
  }

  void _analyticsPurchase() {
    ISpect.logger.analyticsEvent(
      source: 'firebase_analytics',
      event: 'purchase',
      parameters: {
        'transaction_id': 'txn_abc123',
        'value': 79.99,
        'currency': 'USD',
        'items': [
          {'item_id': 'prod_789', 'item_name': 'Pro Widget', 'quantity': 1},
          {'item_id': 'prod_456', 'item_name': 'Extra Pack', 'quantity': 2},
        ],
      },
    );
  }

  // ── Payment ───────────────────────────────────────────────────────────

  Future<void> _paymentPurchase() async {
    await ISpect.logger.paymentTrace<Map<String, Object?>>(
      source: 'stripe',
      operation: 'charge',
      productId: 'prod_premium_monthly',
      amount: 9.99,
      currency: 'USD',
      meta: {'customerId': 'cus_abc123', 'paymentMethod': 'pm_card_visa'},
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        return {
          'chargeId': 'ch_1234567890',
          'status': 'succeeded',
          'receiptUrl': 'https://pay.stripe.com/receipts/...',
        };
      },
      projectResult: (r) => {'chargeId': r['chargeId'], 'status': r['status']},
    );
  }

  Future<void> _paymentRefund() async {
    await ISpect.logger.paymentTrace<Map<String, Object?>>(
      source: 'stripe',
      operation: 'refund',
      amount: 9.99,
      currency: 'USD',
      meta: {'chargeId': 'ch_1234567890', 'reason': 'requested_by_customer'},
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return {'refundId': 're_0987654321', 'status': 'succeeded'};
      },
      projectResult: (r) => {'refundId': r['refundId']},
    );
  }

  Future<void> _paymentSubscription() async {
    await ISpect.logger.paymentTrace<Map<String, Object?>>(
      source: 'revenue_cat',
      operation: 'purchase',
      productId: 'rc_pro_annual',
      amount: 79.99,
      currency: 'USD',
      meta: {
        'offering': 'default',
        'package': 'annual',
        'store': 'app_store',
      },
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return {
          'transactionId': 'txn_rc_999',
          'entitlements': ['pro'],
          'expiresAt': '2027-03-30T00:00:00Z',
        };
      },
      projectResult: (r) => {
        'transactionId': r['transactionId'],
        'entitlements': r['entitlements'],
      },
    );
  }

  // ── gRPC ──────────────────────────────────────────────────────────────

  Future<void> _grpcUnary() async {
    await ISpect.logger.grpcTrace<Map<String, Object?>>(
      source: 'grpc',
      operation: 'unary',
      service: 'UserService',
      method: 'GetProfile',
      grpcMetadata: {
        'authorization': 'Bearer eyJ...',
        'x-request-id': 'req_grpc_001',
      },
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 45));
        return {
          'userId': 'usr_abc123',
          'displayName': 'John Doe',
          'avatarUrl': 'https://example.com/avatar.jpg',
        };
      },
      projectResult: (profile) => {'userId': profile['userId']},
    );
  }

  Future<void> _grpcServerStream() async {
    await ISpect.logger.grpcTrace<List<String>>(
      source: 'grpc',
      operation: 'server-stream',
      service: 'ChatService',
      method: 'StreamMessages',
      grpcMetadata: {'x-chat-id': 'chat_42'},
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return ['msg_1', 'msg_2', 'msg_3', 'msg_4', 'msg_5'];
      },
      projectResult: (msgs) => {'messageCount': msgs.length},
    );
  }

  Future<void> _grpcError() async {
    try {
      await ISpect.logger.grpcTrace<void>(
        source: 'grpc',
        operation: 'unary',
        service: 'OrderService',
        method: 'PlaceOrder',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          throw Exception('UNAVAILABLE: service temporarily unavailable');
        },
      );
    } catch (_) {}
  }

  // ── GraphQL ───────────────────────────────────────────────────────────

  Future<void> _graphqlQuery() async {
    await ISpect.logger.graphqlTrace<Map<String, Object?>>(
      source: 'graphql_flutter',
      operation: 'query',
      operationName: 'GetProducts',
      document: '''
query GetProducts(\$limit: Int!, \$category: String) {
  products(limit: \$limit, category: \$category) {
    id
    title
    price
    thumbnail
    rating
  }
}''',
      variables: {'limit': 10, 'category': 'smartphones'},
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return {
          'data': {
            'products': [
              {'id': 1, 'title': 'iPhone 15', 'price': 999, 'rating': 4.5},
              {'id': 2, 'title': 'Galaxy S24', 'price': 899, 'rating': 4.3},
            ],
          },
        };
      },
      projectResult: (r) {
        final products = (r['data'] as Map?)?['products'] as List? ?? [];
        return {'productCount': products.length};
      },
    );
  }

  Future<void> _graphqlMutation() async {
    await ISpect.logger.graphqlTrace<Map<String, Object?>>(
      source: 'graphql_flutter',
      operation: 'mutation',
      operationName: 'AddToCart',
      document: '''
mutation AddToCart(\$productId: ID!, \$quantity: Int!) {
  addToCart(productId: \$productId, quantity: \$quantity) {
    cartId
    totalItems
    totalPrice
  }
}''',
      variables: {'productId': 'prod_789', 'quantity': 2},
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 90));
        return {
          'data': {
            'addToCart': {
              'cartId': 'cart_001',
              'totalItems': 3,
              'totalPrice': 149.97,
            },
          },
        };
      },
      projectResult: (r) {
        final cart = (r['data'] as Map?)?['addToCart'] as Map? ?? {};
        return {'cartId': cart['cartId'], 'totalItems': cart['totalItems']};
      },
    );
  }

  // ── SSE ───────────────────────────────────────────────────────────────

  void _sseConnect() {
    final connectionId = generateTraceId();
    ISpect.logger.sse(
      source: 'sse_client',
      operation: 'connect',
      url: 'https://api.example.com/events/stream',
      correlationId: connectionId,
    );
    ISpect.logger.info('SSE connection ID: $connectionId');
  }

  void _sseEvents() {
    final connectionId = generateTraceId();
    // Simulate a sequence of SSE events
    ISpect.logger.sse(
      source: 'sse_client',
      operation: 'connect',
      url: 'https://api.example.com/notifications',
      correlationId: connectionId,
    );
    for (final event in [
      ('message', 'evt_001', {'text': 'New order #42'}),
      ('status', 'evt_002', {'status': 'processing', 'orderId': 42}),
      ('message', 'evt_003', {'text': 'Order #42 shipped'}),
    ]) {
      ISpect.logger.sse(
        source: 'sse_client',
        operation: 'event',
        url: 'https://api.example.com/notifications',
        eventType: event.$1,
        eventId: event.$2,
        data: event.$3,
        correlationId: connectionId,
      );
    }
  }

  void _sseError() {
    ISpect.logger.sse(
      source: 'sse_client',
      operation: 'error',
      url: 'https://api.example.com/events/stream',
      error: Exception('SSE connection lost: timeout after 30s'),
      errorStackTrace: StackTrace.current,
    );
  }
}

// ---------------------------------------------------------------------------
// Slider control
// ---------------------------------------------------------------------------

class _SliderControl extends StatelessWidget {
  const _SliderControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: displayValue,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            displayValue,
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
