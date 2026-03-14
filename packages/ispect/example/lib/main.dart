import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

// ---------------------------------------------------------------------------
// Observer example
// ---------------------------------------------------------------------------

class SentryISpectObserver implements ISpectObserver {
  @override
  void onError(ISpectLogData err) => log('Sentry onError: ${err.message}');
  @override
  void onException(ISpectLogData err) =>
      log('Sentry onException: ${err.message}');
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
// Entry point
// ---------------------------------------------------------------------------

void main() {
  final logger = ISpectFlutter.init();
  logger.addObserver(SentryISpectObserver());
  ISpect.run(logger: logger, () => runApp(const MyApp()));
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
      supportedLocales: _localeOptions.map((o) => o.locale),
      localizationsDelegates: ISpectLocalizations.delegates(),
      navigatorObservers:
          ISpectNavigatorObserver.observers(additional: [_observer]),
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
          onOpenFile: (path) async => OpenFilex.open(path),
          onShare: (req) async => SharePlus.instance.share(ShareParams(
            text: req.text,
            subject: req.subject,
            files: req.filePaths.map(XFile.new).toList(),
          )),
        ),
        theme: ISpectTheme(
          pageTitle: 'Debug',
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
                    kISpectEnabled
                        ? Icons.check_circle
                        : Icons.cancel,
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
              'created': DateTime.now()
                  .subtract(Duration(hours: i))
                  .toIso8601String(),
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
              ISpect.logger.info('Mixed #$n [INFO]',
                  additionalData: {'d': data});
            case 'debug':
              ISpect.logger.debug('Mixed #$n [DEBUG]',
                  additionalData: {'d': nested});
            case 'warning':
              ISpect.logger.warning('Mixed #$n [WARN]',
                  additionalData: {'d': data});
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
    return List.generate(size, (i) => {
          'index': i,
          'id': 'item_${i.toString().padLeft(4, '0')}',
          'name': 'Element #$i',
          'active': i.isEven,
          if (nestingDepth > 0)
            'nested': _buildNestedMap(nestingDepth, (size ~/ 3).clamp(1, 3)),
        });
  }
}

// ---------------------------------------------------------------------------
// Quick log buttons grid
// ---------------------------------------------------------------------------

class _QuickLogsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logs = <(String, IconData, Color, VoidCallback)>[
      ('Info', Icons.info_outline, Colors.blue,
          () => ISpect.logger.info('Info message')),
      ('Debug', Icons.bug_report_outlined, Colors.green,
          () => ISpect.logger.debug('Debug message')),
      ('Warning', Icons.warning_amber, Colors.orange,
          () => ISpect.logger.warning('Warning message')),
      ('Error', Icons.error_outline, Colors.red,
          () => ISpect.logger.error('Error message')),
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
      ('Good', Icons.check_circle_outline, Colors.teal,
          () => ISpect.logger.good('All systems operational')),
      ('Verbose', Icons.text_snippet_outlined, Colors.grey,
          () => ISpect.logger.verbose('Verbose trace')),
      ('Print', Icons.terminal, Colors.blueGrey,
          () => ISpect.logger.print('Print log')),
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
