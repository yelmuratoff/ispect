import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class SentryISpectObserver implements ISpectObserver {
  @override
  void onError(ISpectLogData err) => log('Sentry onError: ${err.message}');
  @override
  void onException(ISpectLogData err) =>
      log('Sentry onException: ${err.message}');
  @override
  void onLog(ISpectLogData data) => log('Sentry onLog: ${data.message}');
}

void main() {
  final logger = ISpectFlutter.init();
  logger.addObserver(SentryISpectObserver());
  ISpect.run(logger: logger, () => runApp(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final observer = ISpectNavigatorObserver();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ISpectLocalizations.delegates(),
      navigatorObservers:
          ISpectNavigatorObserver.observers(additional: [observer]),
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      builder: (_, child) => ISpectBuilder.wrap(
        child: child!,
        options: ISpectOptions(
          observer: observer,
          onOpenFile: (path) async => OpenFilex.open(path),
          onShare: (req) async => SharePlus.instance.share(ShareParams(
            text: req.text,
            subject: req.subject,
            files: req.filePaths.map(XFile.new).toList(),
          )),
        ),
        theme: ISpectTheme(pageTitle: 'Debug'),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _logCount = 10;
  double _listSize = 5;
  double _nestingDepth = 2;
  bool _isGenerating = false;

  Map<String, dynamic> _buildNestedMap(int depth, int breadth) {
    if (depth <= 0) {
      return {
        'value': 'leaf_data',
        'timestamp': DateTime.now().toIso8601String(),
        'tags': List.generate(breadth, (i) => 'tag_$i'),
      };
    }
    return {
      'level': depth,
      'items': List.generate(
        breadth,
        (i) => {'item_$i': _buildNestedMap(depth - 1, breadth.clamp(1, 3))},
      ),
      'metadata': {
        'created': DateTime.now().toIso8601String(),
        'depth': depth,
        'childCount': breadth,
      },
    };
  }

  List<Map<String, dynamic>> _buildList(int size, int nestingDepth) {
    return List.generate(size, (i) {
      return {
        'index': i,
        'id': 'item_${i.toString().padLeft(4, '0')}',
        'name': 'Element #$i',
        'active': i.isEven,
        'score': (i * 3.14).toStringAsFixed(2),
        if (nestingDepth > 0)
          'nested': _buildNestedMap(nestingDepth, (size ~/ 3).clamp(1, 3)),
      };
    });
  }

  Future<void> _generateLogs({
    required String type,
    required int count,
    required int listSize,
    required int nestingDepth,
  }) async {
    setState(() => _isGenerating = true);

    final data = _buildList(listSize, nestingDepth);
    final nestedPayload = _buildNestedMap(nestingDepth, listSize.clamp(1, 5));

    for (var i = 0; i < count; i++) {
      final index = i + 1;
      switch (type) {
        case 'info':
          ISpect.logger.info(
            'Info log #$index: Processing batch with $listSize items, '
            'nesting depth: $nestingDepth',
            additionalData: {
              'batchIndex': index,
              'totalBatches': count,
              'payload': nestedPayload,
              'items': data,
            },
          );
        case 'debug':
          ISpect.logger.debug(
            'Debug log #$index: State snapshot with ${data.length} entries',
            additionalData: {
              'snapshot': {
                'index': index,
                'list': data,
                'nested': nestedPayload,
                'config': {
                  'listSize': listSize,
                  'nestingDepth': nestingDepth,
                  'totalLogs': count,
                },
              },
            },
          );
        case 'warning':
          ISpect.logger.warning(
            'Warning log #$index: Slow query detected — '
            '$listSize rows, depth $nestingDepth',
            additionalData: {
              'query': 'SELECT * FROM items LIMIT $listSize',
              'duration_ms': index * 42,
              'rows': data,
              'plan': nestedPayload,
            },
          );
        case 'error':
          ISpect.logger.error(
            'Error log #$index: Failed to process batch',
            exception: Exception(
              'BatchProcessingError: $listSize items, depth $nestingDepth',
            ),
            stackTrace: StackTrace.current,
            additionalData: {
              'failedAt': index,
              'input': data,
              'context': nestedPayload,
            },
          );
        case 'verbose':
          ISpect.logger.verbose(
            'Verbose log #$index: Full trace — $listSize items, '
            'nesting $nestingDepth',
            additionalData: {
              'trace': {
                'step': index,
                'data': data,
                'tree': nestedPayload,
                'env': {
                  'platform': 'flutter',
                  'mode': 'debug',
                  'timestamp': DateTime.now().toIso8601String(),
                },
              },
            },
          );
        case 'critical':
          ISpect.logger.critical(
            'Critical log #$index: System failure detected',
            exception: Exception(
              'CriticalFailure: cascade at depth $nestingDepth',
            ),
            stackTrace: StackTrace.current,
            additionalData: {
              'severity': 'critical',
              'affectedItems': data,
              'failureTree': nestedPayload,
            },
          );
        case 'mixed':
          final logTypes = ['info', 'debug', 'warning', 'error', 'verbose'];
          final logType = logTypes[i % logTypes.length];
          switch (logType) {
            case 'info':
              ISpect.logger.info('Mixed #$index [INFO]: batch item',
                  additionalData: {'items': data, 'nested': nestedPayload});
            case 'debug':
              ISpect.logger.debug('Mixed #$index [DEBUG]: state dump',
                  additionalData: {'items': data, 'nested': nestedPayload});
            case 'warning':
              ISpect.logger.warning('Mixed #$index [WARN]: threshold reached',
                  additionalData: {'items': data, 'nested': nestedPayload});
            case 'error':
              ISpect.logger.error(
                'Mixed #$index [ERROR]: operation failed',
                exception: Exception('MixedError #$index'),
                stackTrace: StackTrace.current,
                additionalData: {'items': data, 'nested': nestedPayload},
              );
            case 'verbose':
              ISpect.logger.verbose('Mixed #$index [VERBOSE]: full details',
                  additionalData: {'items': data, 'nested': nestedPayload});
          }
      }

      // Yield to UI every 100 logs to avoid freezing.
      if (i % 100 == 99) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _logCount.round();
    final listSize = _listSize.round();
    final nestingDepth = _nestingDepth.round();

    return Scaffold(
      appBar: AppBar(title: const Text('ISpect Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ISpect: ${kISpectEnabled ? "ENABLED" : "DISABLED"}',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // --- Simple logs ---
          Text('Simple Logs', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SimpleLogButton(
                label: 'Info',
                icon: Icons.info,
                color: Colors.blue,
                onPressed: () => ISpect.logger.info('Info message!'),
              ),
              _SimpleLogButton(
                label: 'Warning',
                icon: Icons.warning,
                color: Colors.orange,
                onPressed: () => ISpect.logger.warning('Warning!'),
              ),
              _SimpleLogButton(
                label: 'Error',
                icon: Icons.error,
                color: Colors.red,
                onPressed: () => ISpect.logger.error('Error!'),
              ),
              _SimpleLogButton(
                label: 'Exception',
                icon: Icons.dangerous,
                color: Colors.red.shade900,
                onPressed: () => ISpect.logger.handle(
                  exception: Exception('Test'),
                  stackTrace: StackTrace.current,
                ),
              ),
              _SimpleLogButton(
                label: 'Debug',
                icon: Icons.bug_report,
                color: Colors.green,
                onPressed: () => ISpect.logger.debug('Debug message!'),
              ),
              _SimpleLogButton(
                label: 'Verbose',
                icon: Icons.text_snippet,
                color: Colors.grey,
                onPressed: () => ISpect.logger.verbose('Verbose message!'),
              ),
              _SimpleLogButton(
                label: 'Critical',
                icon: Icons.local_fire_department,
                color: Colors.deepOrange,
                onPressed: () => ISpect.logger.critical(
                  'Critical failure!',
                  exception: Exception('CriticalTest'),
                  stackTrace: StackTrace.current,
                ),
              ),
              _SimpleLogButton(
                label: 'Good',
                icon: Icons.check_circle,
                color: Colors.teal,
                onPressed: () => ISpect.logger.good('All systems operational'),
              ),
              _SimpleLogButton(
                label: 'Print',
                icon: Icons.print,
                color: Colors.blueGrey,
                onPressed: () => ISpect.logger.print('Simple print log'),
              ),
            ],
          ),
          const Divider(height: 32),

          // --- Stress test controls ---
          Text('Stress Test', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          _SliderControl(
            label: 'Log count',
            value: _logCount,
            min: 1,
            max: 10000,
            divisions: 99,
            displayValue: count.toString(),
            onChanged: (v) => setState(() => _logCount = v),
          ),
          _SliderControl(
            label: 'List size per log',
            value: _listSize,
            min: 1,
            max: 100,
            divisions: 99,
            displayValue: listSize.toString(),
            onChanged: (v) => setState(() => _listSize = v),
          ),
          _SliderControl(
            label: 'Nesting depth',
            value: _nestingDepth,
            min: 0,
            max: 6,
            divisions: 6,
            displayValue: nestingDepth.toString(),
            onChanged: (v) => setState(() => _nestingDepth = v),
          ),

          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '$count logs × $listSize list items × '
                '$nestingDepth nesting depth',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_isGenerating)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final entry in [
                  ('Info', Icons.info, Colors.blue, 'info'),
                  ('Debug', Icons.bug_report, Colors.green, 'debug'),
                  ('Warning', Icons.warning, Colors.orange, 'warning'),
                  ('Error', Icons.error, Colors.red, 'error'),
                  ('Verbose', Icons.text_snippet, Colors.grey, 'verbose'),
                  (
                    'Critical',
                    Icons.local_fire_department,
                    Colors.deepOrange,
                    'critical'
                  ),
                  ('Mixed', Icons.shuffle, Colors.purple, 'mixed'),
                ])
                  FilledButton.tonalIcon(
                    onPressed: () => _generateLogs(
                      type: entry.$4,
                      count: count,
                      listSize: listSize,
                      nestingDepth: nestingDepth,
                    ),
                    icon: Icon(entry.$2, size: 18),
                    label: Text(entry.$1),
                    style: FilledButton.styleFrom(
                      foregroundColor: entry.$3,
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SimpleLogButton extends StatelessWidget {
  const _SimpleLogButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(foregroundColor: color),
    );
  }
}

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
          width: 120,
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
          width: 56,
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
