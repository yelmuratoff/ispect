import 'package:flutter/material.dart';
import 'package:ispectify_db_example/examples/drift_codegen_example.dart';
import 'package:ispectify_db_example/examples/drift_example.dart';
import 'package:ispectify_db_example/examples/firebase_firestore_example.dart';
import 'package:ispectify_db_example/examples/flutter_secure_storage_example.dart';
import 'package:ispectify_db_example/examples/hive_example.dart';
import 'package:ispectify_db_example/examples/isar_example.dart';
import 'package:ispectify_db_example/examples/sembast_example.dart';
import 'package:ispectify_db_example/examples/shared_preferences_example.dart';
import 'package:ispectify_db_example/examples/sqflite_example.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Provide mock for shared_preferences if running tests/desktop without plugin
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISpect DB Examples',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ExamplesPage(),
    );
  }
}

class ExamplesPage extends StatefulWidget {
  const ExamplesPage({super.key});

  @override
  State<ExamplesPage> createState() => _ExamplesPageState();
}

class _ExamplesPageState extends State<ExamplesPage> {
  final Map<String, Future<void> Function()> _examples = {
    'Drift': driftExample,
    'Drift (Codegen)': driftCodegenExample,
    'Firebase Firestore (Fake)': firestoreExample,
    'Flutter Secure Storage': secureStorageExample,
    'Hive': hiveExample,
    'Isar': isarExample,
    'Sembast': sembastExample,
    'Shared Preferences': sharedPreferencesExample,
    'Sqflite': sqfliteExample,
  };

  String _status = 'Ready';
  bool _isRunning = false;

  Future<void> _runExample(String name, Future<void> Function() runner) async {
    setState(() {
      _isRunning = true;
      _status = 'Running $name...';
    });
    try {
      await runner();
      setState(() {
        _status = 'Success: $name';
      });
    } catch (e, st) {
      setState(() {
        _status = 'Error in $name: $e';
      });
      debugPrint('Error: $e\n$st');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISpect DB Interceptors')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey.shade900,
            width: double.infinity,
            child: Text(
              _status,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isRunning) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _examples.length,
              itemBuilder: (context, index) {
                final entry = _examples.entries.elementAt(index);
                return ListTile(
                  title: Text(entry.key),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: _isRunning
                      ? null
                      : () => _runExample(entry.key, entry.value),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isRunning
                  ? null
                  : () async {
                      for (final entry in _examples.entries) {
                        await _runExample(entry.key, entry.value);
                      }
                      setState(() {
                        _status = 'All examples completed!';
                      });
                    },
              child: const Text('Run All Examples'),
            ),
          )
        ],
      ),
    );
  }
}
