import 'package:flutter/material.dart';

void main() {
  // final logger = Logger(
  //   customLogs: {
  //     'SUCCESS': const SuccessLog(),
  //   },
  // );

  // logger.log('Application started', logObject: const InfoLog());
  // logger.log('Low disk space', logObject: const WarningLog());
  // logger.log('Unhandled exception occurred', logObject: const ErrorLog());
  // logger.log('Operation completed successfully', logObject: const SuccessLog());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ISpect Example'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('Show Toast'),
          ),
        ),
      ),
    );
  }
}
