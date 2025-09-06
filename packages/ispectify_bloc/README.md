<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>BLoC state management integration for ISpectify logging system</strong></p>
  
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

## 🔍 Overview

> **ISpectify BLoC** provides seamless integration between BLoC state management and the ISpectify logging system.

<div align="center">

🔄 **State Tracking** • 📝 **Event Logging** • 🔍 **Transition Monitoring** • ❌ **Error Handling**

</div>

Enhance your BLoC debugging workflow by automatically capturing and logging all state management interactions. Perfect for tracking state changes, debugging complex flows, and monitoring application behavior.

### 🎯 Key Features

- 🔄 **State Change Logging**: Automatic logging of all BLoC state changes
- 📝 **Event Tracking**: Detailed event logging with parameters
- 🔍 **Transition Monitoring**: Complete state transition tracking
- ❌ **Error Handling**: BLoC error logging with stack traces
- ⚡ **Performance Metrics**: State change timing and performance tracking
- 🎛️ **Configurable**: Flexible filtering and formatting options

## 🔧 Configuration Options

### Basic Setup

```dart
// Initialize in ISpect.run onInit callback
ISpect.run(
  () => runApp(MyApp()),
  logger: iSpectify,
  onInit: () {
    // Set up BLoC observer for automatic logging
    Bloc.observer = ISpecBlocObserver(
      iSpectify: iSpectify,
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

## 📦 Installation

Add ispectify_bloc to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_bloc: ^4.3.2
```

## ⚠️ Security & Production Guidelines

> **🚨 IMPORTANT: ISpect is a debugging tool and should NEVER be included in production builds**

### 🔒 Production Safety

ISpect contains sensitive debugging information and should only be used in development and staging environments. To ensure ISpect is completely removed from production builds, use the following approach:

### ✅ Recommended Setup with Dart Define Constants

**1. Create environment-aware initialization:**

```dart
// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Use dart define to control ISpect inclusion
const bool kEnableISpect = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

void main() {
  if (kEnableISpect) {
    // Initialize ISpect only in development/staging
    _initializeISpect();
  } else {
    // Production initialization without ISpect
    runApp(MyApp());
  }
}

void _initializeISpect() {
  // ISpect initialization code here
  // This entire function will be tree-shaken in production
}
```

**2. Build Commands:**

```bash
# Development build (includes ISpect)
flutter run --dart-define=ENABLE_ISPECT=true

# Staging build (includes ISpect)
flutter build appbundle --dart-define=ENABLE_ISPECT=true

# Production build (ISpect completely removed via tree-shaking)
flutter build appbundle --dart-define=ENABLE_ISPECT=false
# or simply:
flutter build appbundle  # defaults to false
```

**3. Conditional Widget Wrapping:**

```dart
Widget build(BuildContext context) {
  Widget app = MaterialApp(/* your app */);
  
  // Wrap with ISpect only when enabled
  if (kEnableISpect) {
    app = ISpectBuilder(child: app);
  }
  
  return app;
}
```

### 🛡️ Security Benefits

- ✅ **Zero Production Footprint**: Tree-shaking removes all ISpect code from release builds
- ✅ **No Sensitive Data Exposure**: Debug information never reaches production users
- ✅ **Performance Optimized**: No debugging overhead in production
- ✅ **Compliance Ready**: Meets security requirements for app store releases

### 🔍 Verification

To verify ISpect is not included in your production build:

```bash
# Build release APK and check size difference
flutter build apk --dart-define=ENABLE_ISPECT=false --release
flutter build apk --dart-define=ENABLE_ISPECT=true --release

# Use flutter tools to analyze bundle
flutter analyze --dart-define=ENABLE_ISPECT=false
```

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
        iSpectify: iSpectify,
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

## 📚 Examples

See the [example/](example/) directory for complete integration examples with different BLoC patterns.

## 🏗️ Architecture

ISpectifyBloc integrates with the BLoC library through observers:

| Component | Description |
|-----------|-----------|
| **BLoC Observer** | Captures all BLoC events and state changes |
| **Event Logger** | Logs events with parameters and metadata |
| **State Logger** | Logs state changes and transitions |
| **Error Handler** | Captures and logs BLoC errors |
| **Performance Tracker** | Measures state change performance |

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

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