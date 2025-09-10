<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>BLoC state management integration for ISpect toolkit</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_bloc">
      <img src="https://img.shields.io/pub/v/ispectify_bloc.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/K1yoshiSho/ispect">
      <img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_bloc/score">
      <img src="https://img.shields.io/pub/likes/ispectify_bloc?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_bloc/score">
      <img src="https://img.shields.io/pub/points/ispectify_bloc?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## TL;DR

Observe BLoC/Cubit events, transitions, states with selective filtering.

## 🏗️ Architecture

ISpectifyBloc integrates with the BLoC library through observers:

| Component | Description |
|-----------|-----------|
| **BLoC Observer** | Captures all BLoC events and state changes |
| **Event Logger** | Logs events with parameters and metadata |
| **State Logger** | Logs state changes and transitions |
| **Error Handler** | Captures and logs BLoC errors |
| **Performance Tracker** | Measures state change performance |

## Overview

> **ISpectify BLoC** integrates BLoC state management with the ISpectify logging system.

ISpectifyBloc integrates BLoC state management with the ISpectify logging system for state change monitoring.

### Key Features

- State Change Logging: Automatic logging of all BLoC state changes
- Event Tracking: Detailed event logging with parameters
- Transition Monitoring: Complete state transition tracking
- Error Handling: BLoC error logging with stack traces
- Performance Metrics: State change timing and performance tracking
- Configurable: Flexible filtering and formatting options

## Configuration Options

### Basic Setup

```dart
// Initialize in ISpect.run onInit callback
ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    // Set up BLoC observer for automatic logging
    Bloc.observer = ISpecBlocObserver(
      logger: iSpectify,
    );
  },
);
```

### Filtering BLoC Logs

```dart
// You can disable specific BLoC logs in ISpectTheme
ISpectBuilder(
  theme: const ISpectTheme(
    logDescriptions: [
      LogDescription(
        key: 'bloc-event',
        isDisabled: true, // Disable event logs
      ),
      LogDescription(
        key: 'bloc-transition',
        isDisabled: true, // Disable transition logs
      ),
      LogDescription(
        key: 'bloc-close',
        isDisabled: true, // Disable close logs
      ),
      LogDescription(
        key: 'bloc-create',
        isDisabled: true, // Disable create logs
      ),
      LogDescription(
        key: 'bloc-state',
        isDisabled: true, // Disable state logs
      ),
    ],
  ),
  child: child,
)
```

### Using with Different BLoC Types

```dart
// Works with Cubit
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

// Works with BLoC
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterIncremented>((event, emit) {
      emit(state + 1);
    });
  }
}

// All state changes will be automatically logged
```

## Installation

Add ispectify_bloc to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_bloc: ^4.3.6
```

## Security & Production Guidelines

> IMPORTANT: ISpect is development‑only. Keep it out of production builds.

<details>
<summary><strong>Full security & environment setup (click to expand)</strong></summary>

</details>

## 🚀 Quick Start

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispect/ispect.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';

// Use dart define to control ISpectify BLoC integration
const bool kEnableISpectBloc = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

void main() {
  if (kEnableISpectBloc) {
    _initializeWithISpect();
  } else {
    // Production initialization without ISpect
    runApp(MyApp());
  }
}

void _initializeWithISpect() {
  final ISpectify iSpectify = ISpectifyFlutter.init();

  ISpect.run(
    () => runApp(MyApp()),
    logger: iSpectify,
    onInit: () {
      // Set up BLoC observer only in development/staging
      Bloc.observer = ISpecBlocObserver(
        logger: iSpectify,
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => CounterCubit(),
        child: const CounterPage(),
      ),
    );
  }
}

// Your Cubit/BLoC will be automatically logged only when ISpect is enabled
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  
  void load({required String data}) {
    // State changes will be logged only when ISpect is enabled
    emit(state + 1);
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISpectify BLoC Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BlocBuilder<CounterCubit, int>(
              builder: (context, state) {
                return Text('Count: $state');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // This state change will be logged only when enabled
                context.read<CounterCubit>().increment();
              },
              child: const Text('Increment'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // This state change will also be logged only when enabled
                context.read<CounterCubit>().load(data: 'Test data');
              },
              child: const Text('Load Data'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Minimal Setup

## Examples

See the [example/](example/) directory for complete integration examples with different BLoC patterns.

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [ispectify](../ispectify) - Foundation logging system
- [ispect](../ispect) - Main debugging interface
- [flutter_bloc](https://pub.dev/packages/flutter_bloc) - BLoC state management library
- [bloc](https://pub.dev/packages/bloc) - Core BLoC library

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>