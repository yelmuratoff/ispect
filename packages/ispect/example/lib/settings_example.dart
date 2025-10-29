import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

/// Example demonstrating ISpect settings persistence and log type filtering.
///
/// This example shows:
/// 1. How to load and save settings (using in-memory storage for demo)
/// 2. How to initialize ISpect with saved settings
/// 3. How to apply log type filters
/// 4. How settings automatically persist when changed in UI
///
/// Note: In production, replace `_InMemoryStorage` with actual persistence
/// like SharedPreferences, Hive, or secure_storage.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved settings
  final initialSettings = await _InMemoryStorage.load();

  // Initialize ISpect logger with saved configuration
  final logger = ISpectFlutter.init(
    options: initialSettings != null
        ? ISpectLoggerOptions(
            enabled: initialSettings.enabled,
            useConsoleLogs: initialSettings.useConsoleLogs,
            useHistory: initialSettings.useHistory,
          )
        : null,
    filter: initialSettings?.enabledLogTypes.isNotEmpty ?? false
        ? ISpectFilter(
            logTypeKeys: initialSettings!.enabledLogTypes.toList(),
          )
        : null,
  );

  // Initialize ISpect instance
  ISpect.initialize(logger);

  runApp(
    MyApp(
      initialSettings: initialSettings,
    ),
  );
}

/// Simple in-memory storage for demo purposes.
/// Replace with SharedPreferences or other storage in production.
class _InMemoryStorage {
  static String? _savedSettings;

  static Future<ISpectSettingsState?> load() async {
    if (_savedSettings == null) return null;
    try {
      final json = jsonDecode(_savedSettings!) as Map<String, dynamic>;
      return ISpectSettingsState.fromJson(json);
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      return null;
    }
  }

  static Future<void> save(ISpectSettingsState settings) async {
    try {
      _savedSettings = jsonEncode(settings.toJson());
      debugPrint(
          'Settings saved: ${settings.enabledLogTypes.length} log types enabled');

      // Apply settings to logger when they change
      ISpect.logger.configure(
        options: ISpect.logger.options.copyWith(
          enabled: settings.enabled,
          useConsoleLogs: settings.useConsoleLogs,
          useHistory: settings.useHistory,
        ),
        filter: settings.enabledLogTypes.isNotEmpty
            ? ISpectFilter(
                logTypeKeys: settings.enabledLogTypes.toList(),
              )
            : null,
      );
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.initialSettings,
    super.key,
  });

  final ISpectSettingsState? initialSettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISpect Settings Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Wrap app with ISpect
        return ISpectBuilder(
          options: ISpectOptions(
            observer: null,
            initialSettings: initialSettings,
            onSettingsChanged: _InMemoryStorage.save,
          ),
          child: child!,
        );
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISpect Settings Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tap buttons to generate different log types:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _LogButton(
              label: 'HTTP Request',
              color: Colors.purple,
              onPressed: () {
                ISpect.logger.log(
                  'GET /api/users',
                  type: ISpectLogType.httpRequest,
                );
              },
            ),
            _LogButton(
              label: 'HTTP Response',
              color: Colors.cyan,
              onPressed: () {
                ISpect.logger.log(
                  '200 OK - Users fetched',
                  type: ISpectLogType.httpResponse,
                );
              },
            ),
            _LogButton(
              label: 'BLoC Event',
              color: Colors.blue,
              onPressed: () {
                ISpect.logger.log(
                  'UserEvent.loadRequested',
                  type: ISpectLogType.blocEvent,
                );
              },
            ),
            _LogButton(
              label: 'Database Query',
              color: Colors.green,
              onPressed: () {
                ISpect.logger.log(
                  'SELECT * FROM users WHERE id = 1',
                  type: ISpectLogType.dbQuery,
                );
              },
            ),
            _LogButton(
              label: 'Error',
              color: Colors.red,
              onPressed: () {
                ISpect.logger.error(
                  'Something went wrong',
                  exception: Exception('Test error'),
                );
              },
            ),
            _LogButton(
              label: 'Info',
              color: Colors.blue.shade300,
              onPressed: () {
                ISpect.logger.info('Information message');
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Open ISpect panel to view logs and change settings',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _InfoCard(),
          ],
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  const _LogButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings Features:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const _BulletPoint(
              text: 'Enable/disable specific log types',
            ),
            const _BulletPoint(
              text: 'Settings automatically save (in-memory for demo)',
            ),
            const _BulletPoint(
              text:
                  'Replace _InMemoryStorage with SharedPreferences in production',
            ),
            const _BulletPoint(
              text: 'Filter logs by category (HTTP, BLoC, DB, etc.)',
            ),
            const _BulletPoint(
              text: 'Toggle console output and history',
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
